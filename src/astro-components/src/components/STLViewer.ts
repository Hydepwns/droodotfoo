/**
 * STL Viewer Client-Side Logic
 * Three.js-based 3D model viewer for Astro component
 */

import * as THREE from 'three';
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader.js';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

interface STLViewerClientOptions {
  componentId?: string;
  onModelLoaded?: (info: ModelInfo) => void;
  onModelError?: (error: string) => void;
}

interface ModelInfo {
  triangles: number;
  vertices: number;
  bounds: {
    width: number;
    height: number;
    depth: number;
  };
}

export class STLViewerClient {
  private el: HTMLElement;
  private scene?: THREE.Scene;
  private camera?: THREE.PerspectiveCamera;
  private renderer?: THREE.WebGLRenderer;
  private controls?: OrbitControls;
  private mesh?: THREE.Mesh | THREE.Points;
  private animationId?: number;
  private options: STLViewerClientOptions;
  private componentId: string;

  constructor(el: HTMLElement, options: STLViewerClientOptions = {}) {
    this.el = el;
    this.options = options;
    this.componentId = options.componentId || 'default';
    
    console.log('STL Viewer Client initialized');
    this.init();
  }

  private init() {
    // Find canvas container
    const canvasContainer = this.el.querySelector('#stl-canvas-container') as HTMLElement;
    if (!canvasContainer) {
      console.error('Canvas container not found');
      return;
    }

    // Create canvas element
    const canvas = document.createElement('canvas');
    canvas.id = `stl-canvas-${this.componentId}`;
    canvasContainer.appendChild(canvas);

    // Position canvas
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

    // Load sample model
    this.loadModel('/models/cube.stl');
  }

  public loadModel(url: string) {
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

        const modelInfo: ModelInfo = {
          triangles,
          vertices,
          bounds: {
            width: size.x * scale,
            height: size.y * scale,
            depth: size.z * scale
          }
        };

        // Notify parent component
        if (this.options.onModelLoaded) {
          this.options.onModelLoaded(modelInfo);
        }

        console.log('STL model loaded:', url);
      },
      (progress) => {
        console.log('Loading:', (progress.loaded / progress.total) * 100 + '%');
      },
      (error) => {
        console.error('Error loading STL:', error);
        if (this.options.onModelError) {
          this.options.onModelError(error.message);
        }
      }
    );
  }

  public setRenderMode(mode: string) {
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
  }

  public rotateCamera(axis?: string, angle: number = 0.1) {
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
  }

  public resetCamera() {
    if (!this.camera || !this.controls) return;

    this.camera.position.set(0, 0, 5);
    this.camera.lookAt(0, 0, 0);
    this.controls.target.set(0, 0, 0);
    this.controls.update();
  }

  public zoom(distance: number) {
    if (!this.camera) return;

    const direction = new THREE.Vector3();
    this.camera.getWorldDirection(direction);
    this.camera.position.addScaledVector(direction, distance);
  }

  public cycleRenderMode() {
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
  }

  private positionCanvas() {
    const canvasContainer = this.el.querySelector('#stl-canvas-container') as HTMLElement;
    const canvas = canvasContainer?.querySelector('canvas') as HTMLCanvasElement;

    if (!canvas || !canvasContainer) return;

    // Get computed styles for precise positioning
    const wrapperStyles = window.getComputedStyle(this.el);
    const fontSize = parseFloat(wrapperStyles.fontSize);
    const lineHeightRatio = 1.2;
    const lineHeight = fontSize * lineHeightRatio;

    // 3D Viewport position in HUD grid
    // Viewport border is at row 8 (0-indexed)
    // Viewport content starts at row 9, column 4
    const viewportStartRow = 9;
    const viewportStartCol = 4;
    const viewportWidth = 60; // Characters wide
    const viewportHeight = 7; // Lines tall

    // Calculate positions
    const topPx = viewportStartRow * lineHeight;
    const leftCh = viewportStartCol;
    const widthCh = viewportWidth;
    const heightEm = viewportHeight * lineHeightRatio;

    // Apply positioning to container
    canvasContainer.style.position = 'absolute';
    canvasContainer.style.top = `${topPx}px`;
    canvasContainer.style.left = `${leftCh}ch`;
    canvasContainer.style.width = `${widthCh}ch`;
    canvasContainer.style.height = `${heightEm}em`;

    // Size the canvas to fill container
    canvas.style.width = '100%';
    canvas.style.height = '100%';

    console.log('STL Canvas positioned:', {
      containerTop: `${topPx}px`,
      containerLeft: `${leftCh}ch`,
      canvasWidth: `${widthCh}ch`,
      canvasHeight: `${heightEm}em`,
      lineHeight: lineHeight
    });
  }

  public destroy() {
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
}

export default STLViewerClient;
