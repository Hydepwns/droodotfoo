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
      canvas.style.width = '100%';
      canvas.style.height = '400px';
      canvas.style.display = 'block';
      this.el.appendChild(canvas);
    }

    // Initialize Three.js scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0a0a0a);

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
