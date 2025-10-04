/**
 * STL Viewer Hook
 * Three.js-based 3D model viewer integrated with Phoenix LiveView
 */

import * as THREE from 'three';
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

interface STLViewerHook {
  mounted: () => void;
  destroyed: () => void;
  scene?: THREE.Scene;
  camera?: THREE.PerspectiveCamera;
  renderer?: THREE.WebGLRenderer;
  controls?: OrbitControls;
  mesh?: THREE.Mesh;
  animationId?: number;
  el: HTMLElement;
  pushEvent?: (event: string, payload: any) => void;
  handleEvent?: (event: string, callback: (payload: any) => void) => void;
}

export const STLViewerHook: Partial<STLViewerHook> = {
  mounted() {
    console.log('STL Viewer mounted');

    // Find or create canvas element
    let canvas = this.el.querySelector('canvas') as HTMLCanvasElement;
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'stl-canvas';
      this.el.appendChild(canvas);
    }

    // Position canvas relative to terminal wrapper
    this.positionCanvas();

    // Initialize Three.js scene
    this.scene = new THREE.Scene();
    // Transparent background to show ASCII art underneath
    this.scene.background = null;

    // Set up camera
    const aspect = canvas.clientWidth / canvas.clientHeight;
    this.camera = new THREE.PerspectiveCamera(45, aspect, 0.1, 1000);
    this.camera.position.set(0, 0, 5);

    // Set up renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      alpha: true
    });
    this.renderer.setClearColor(0x000000, 0); // Transparent background
    this.renderer.setSize(canvas.clientWidth, canvas.clientHeight);
    this.renderer.setPixelRatio(window.devicePixelRatio);

    // Add lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
    this.scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(1, 1, 1);
    this.scene.add(directionalLight);

    const backLight = new THREE.DirectionalLight(0xffffff, 0.3);
    backLight.position.set(-1, -1, -1);
    this.scene.add(backLight);

    // Set up orbit controls
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.minDistance = 1;
    this.controls.maxDistance = 50;

    // Handle window resize
    const handleResize = () => {
      if (!this.camera || !this.renderer || !canvas) return;

      this.positionCanvas();

      const width = canvas.clientWidth;
      const height = canvas.clientHeight;

      this.camera.aspect = width / height;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(width, height);
    };

    window.addEventListener('resize', handleResize);

    // Animation loop
    const animate = () => {
      this.animationId = requestAnimationFrame(animate);

      if (this.controls) {
        this.controls.update();
      }

      if (this.renderer && this.scene && this.camera) {
        this.renderer.render(this.scene, this.camera);
      }
    };
    animate();

    // Listen for LiveView events
    if (this.handleEvent) {
      // Load model event
      this.handleEvent('stl_load', (payload: { url: string }) => {
        this.loadModel(payload.url);
      });

      // Change render mode
      this.handleEvent('stl_mode', (payload: { mode: string }) => {
        this.setRenderMode(payload.mode);
      });

      // Rotate camera
      this.handleEvent('stl_rotate', (payload: { axis?: string; angle?: number }) => {
        this.rotateCamera(payload.axis, payload.angle);
      });

      // Reset camera
      this.handleEvent('stl_reset', () => {
        this.resetCamera();
      });

      // Zoom
      this.handleEvent('stl_zoom', (payload: { distance: number }) => {
        this.zoom(payload.distance);
      });

      // Cycle mode
      this.handleEvent('stl_cycle_mode', () => {
        this.cycleRenderMode();
      });
    }

    // Load sample model
    this.loadModel('/models/cube.stl');
  },

  loadModel(url: string) {
    if (!this.scene) return;

    // Remove existing mesh
    if (this.mesh) {
      this.scene.remove(this.mesh);
      this.mesh = undefined;
    }

    const loader = new STLLoader();

    loader.load(
      url,
      (geometry) => {
        // Center and scale the geometry
        geometry.computeBoundingBox();
        const boundingBox = geometry.boundingBox!;
        const center = new THREE.Vector3();
        boundingBox.getCenter(center);
        geometry.translate(-center.x, -center.y, -center.z);

        // Calculate scale to fit in view
        const size = new THREE.Vector3();
        boundingBox.getSize(size);
        const maxDim = Math.max(size.x, size.y, size.z);
        const scale = 2 / maxDim;
        geometry.scale(scale, scale, scale);

        // Create material
        const material = new THREE.MeshPhongMaterial({
          color: 0x00ffaa,
          specular: 0x111111,
          shininess: 200,
          flatShading: false,
        });

        // Create mesh
        this.mesh = new THREE.Mesh(geometry, material);
        this.scene!.add(this.mesh);

        // Calculate model info
        const triangles = geometry.attributes.position.count / 3;
        const vertices = geometry.attributes.position.count;

        // Send info back to LiveView
        if (this.pushEvent) {
          this.pushEvent('stl_model_loaded', {
            triangles,
            vertices,
            bounds: {
              width: size.x * scale,
              height: size.y * scale,
              depth: size.z * scale
            }
          });
        }

        console.log('STL model loaded:', url);
      },
      (progress) => {
        console.log('Loading:', (progress.loaded / progress.total) * 100 + '%');
      },
      (error) => {
        console.error('Error loading STL:', error);
        if (this.pushEvent) {
          this.pushEvent('stl_load_error', { error: error.message });
        }
      }
    );
  },

  setRenderMode(mode: string) {
    if (!this.mesh) return;

    const material = this.mesh.material as THREE.MeshPhongMaterial;

    switch (mode) {
      case 'wireframe':
        material.wireframe = true;
        break;
      case 'solid':
        material.wireframe = false;
        break;
      case 'points':
        // Create points material
        const geometry = this.mesh.geometry;
        this.scene!.remove(this.mesh);

        const pointsMaterial = new THREE.PointsMaterial({
          color: 0x00ffaa,
          size: 0.02
        });

        this.mesh = new THREE.Points(geometry, pointsMaterial) as any;
        this.scene!.add(this.mesh);
        break;
    }
  },

  rotateCamera(axis?: string, angle: number = 0.1) {
    if (!this.camera) return;

    switch (axis) {
      case 'x':
        this.camera.position.applyAxisAngle(new THREE.Vector3(1, 0, 0), angle);
        break;
      case 'y':
        this.camera.position.applyAxisAngle(new THREE.Vector3(0, 1, 0), angle);
        break;
      case 'z':
        this.camera.position.applyAxisAngle(new THREE.Vector3(0, 0, 1), angle);
        break;
    }

    this.camera.lookAt(0, 0, 0);
  },

  resetCamera() {
    if (!this.camera || !this.controls) return;

    this.camera.position.set(0, 0, 5);
    this.camera.lookAt(0, 0, 0);
    this.controls.target.set(0, 0, 0);
    this.controls.update();
  },

  zoom(distance: number) {
    if (!this.camera) return;

    const direction = new THREE.Vector3();
    this.camera.getWorldDirection(direction);
    this.camera.position.addScaledVector(direction, distance);
  },

  cycleRenderMode() {
    if (!this.mesh) return;

    const currentMaterial = this.mesh.material;

    if (currentMaterial instanceof THREE.MeshPhongMaterial) {
      if (currentMaterial.wireframe) {
        // Wireframe -> Points
        this.setRenderMode('points');
      } else {
        // Solid -> Wireframe
        this.setRenderMode('wireframe');
      }
    } else if (currentMaterial instanceof THREE.PointsMaterial) {
      // Points -> Solid
      this.setRenderMode('solid');
    }
  },

  positionCanvas() {
    const canvas = this.el.querySelector('canvas') as HTMLCanvasElement;
    if (!canvas) return;

    // Find terminal wrapper to calculate position
    const terminalWrapper = document.getElementById('terminal-wrapper');
    if (!terminalWrapper) return;

    // Get terminal wrapper's actual position
    const wrapperRect = terminalWrapper.getBoundingClientRect();

    // Dynamic calculation: Find the "3D Viewport" text in the terminal
    const terminalLines = terminalWrapper.querySelectorAll('.terminal-line');

    // Find the line containing "3D Viewport" border
    let viewportLine: HTMLElement | null = null;
    let viewportRow = -1;
    terminalLines.forEach((line, index) => {
      if (line.textContent && line.textContent.includes('3D Viewport')) {
        viewportLine = line as HTMLElement;
        viewportRow = index;
      }
    });

    if (viewportRow === -1 || !viewportLine) {
      console.warn('Could not find 3D Viewport in terminal');
      return;
    }

    // Get the actual position of the viewport line
    const viewportRect = viewportLine.getBoundingClientRect();

    // Constants
    const lineHeight = 1.2; // em units (matches CSS)

    // Calculate pixel-based positioning
    // The viewport box border is at viewportRect.top
    // Content starts 1 line below the top border
    const contentTopPx = viewportRect.top + viewportRect.height; // 1 line down from border

    // Column positioning: viewport inner content starts at col 38
    const contentStartCol = 38;
    const contentWidth = 60;

    const contentHeight = 7; // lines

    // Position using pixels for top (more accurate), ch for left
    this.el.style.top = `${contentTopPx}px`;
    this.el.style.left = `${contentStartCol}ch`;

    // Set canvas size
    canvas.style.width = `${contentWidth}ch`;
    canvas.style.height = `${contentHeight * lineHeight}em`;

    console.log('Canvas positioned at:', {
      viewportRow,
      viewportLineTop: viewportRect.top,
      calculatedTop: contentTopPx,
      top: `${contentTopPx}px`,
      left: `${contentStartCol}ch`,
      width: `${contentWidth}ch`,
      height: `${contentHeight * lineHeight}em`
    });
  },

  destroyed() {
    // Cancel animation
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }

    // Dispose of Three.js resources
    if (this.renderer) {
      this.renderer.dispose();
    }

    if (this.mesh) {
      this.mesh.geometry.dispose();
      if (this.mesh.material) {
        (this.mesh.material as THREE.Material).dispose();
      }
    }

    console.log('STL Viewer destroyed');
  }
};

export default {
  STLViewerHook
};
