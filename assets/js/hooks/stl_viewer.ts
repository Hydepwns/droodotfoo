/**
 * STL Viewer Hook
 * Three.js-based 3D model viewer integrated with Phoenix LiveView
 *
 * PERFORMANCE: Uses dynamic imports to avoid bundling THREE.js (~600KB) in main bundle.
 * THREE.js is only loaded when STL viewer is actually used.
 */

interface STLViewerHook {
  mounted: () => Promise<void>;
  destroyed: () => void;
  scene?: any;
  camera?: any;
  renderer?: any;
  controls?: any;
  mesh?: any;
  animationId?: number;
  el: HTMLElement;
  pushEvent?: (event: string, payload: any) => void;
  handleEvent?: (event: string, callback: (payload: any) => void) => void;
  THREE?: any;
  STLLoader?: any;
  OrbitControls?: any;
}

export const STLViewerHook: Partial<STLViewerHook> = {
  async mounted() {
    console.log('STL Viewer mounted - loading THREE.js...');

    // Dynamic import of THREE.js (only loaded when STL viewer is used)
    const [THREE, { STLLoader }, { OrbitControls }] = await Promise.all([
      import('three'),
      import('three/examples/jsm/loaders/STLLoader.js'),
      import('three/examples/jsm/controls/OrbitControls.js')
    ]);

    // Store for later use in other methods
    this.THREE = THREE;
    this.STLLoader = STLLoader;
    this.OrbitControls = OrbitControls;

    console.log('THREE.js loaded successfully');

    // Extract component ID from wrapper element
    const wrapperId = this.el.id;
    const componentId = wrapperId.replace('stl-viewer-wrapper-', '');

    // Find canvas container
    const canvasContainer = this.el.querySelector(`#stl-canvas-container-${componentId}`) as HTMLElement;
    if (!canvasContainer) {
      console.error('Canvas container not found');
      return;
    }

    // Create canvas element
    const canvas = document.createElement('canvas');
    canvas.id = `stl-canvas-${componentId}`;
    canvasContainer.appendChild(canvas);

    // Position canvas using simpler grid-based approach
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
    this.controls = new this.OrbitControls(this.camera, this.renderer.domElement);
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

    // Listen for LiveView events from component
    if (this.handleEvent) {
      // Unified command handler
      this.handleEvent('stl_command', (payload: { command: { type: string; [key: string]: any } }) => {
        const { command } = payload;

        switch (command.type) {
          case 'load':
            this.loadModel(command.url);
            break;
          case 'mode':
            this.setRenderMode(command.mode);
            break;
          case 'rotate':
            this.rotateCamera(command.axis, command.angle);
            break;
          case 'reset':
            this.resetCamera();
            break;
          case 'zoom':
            this.zoom(command.distance);
            break;
          default:
            console.warn('Unknown STL command:', command.type);
        }
      });
    }

    // Load sample model
    this.loadModel('/models/cube.stl');
  },

  loadModel(url: string) {
    if (!this.scene || !this.THREE || !this.STLLoader) return;

    // Remove existing mesh
    if (this.mesh) {
      this.scene.remove(this.mesh);
      this.mesh = undefined;
    }

    const loader = new this.STLLoader();

    loader.load(
      url,
      (geometry: any) => {
        // Center and scale the geometry
        geometry.computeBoundingBox();
        const boundingBox = geometry.boundingBox!;
        const center = new this.THREE.Vector3();
        boundingBox.getCenter(center);
        geometry.translate(-center.x, -center.y, -center.z);

        // Calculate scale to fit in view
        const size = new this.THREE.Vector3();
        boundingBox.getSize(size);
        const maxDim = Math.max(size.x, size.y, size.z);
        const scale = 2 / maxDim;
        geometry.scale(scale, scale, scale);

        // Create material
        const material = new this.THREE.MeshPhongMaterial({
          color: 0x00ffaa,
          specular: 0x111111,
          shininess: 200,
          flatShading: false,
        });

        // Create mesh
        this.mesh = new this.THREE.Mesh(geometry, material);
        this.scene!.add(this.mesh);

        // Calculate model info
        const triangles = geometry.attributes.position.count / 3;
        const vertices = geometry.attributes.position.count;

        // Send info back to LiveView component
        if (this.pushEvent) {
          this.pushEvent('model_loaded', {
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
          this.pushEvent('model_error', { error: error.message });
        }
      }
    );
  },

  setRenderMode(mode: string) {
    if (!this.mesh || !this.THREE) return;

    const material = this.mesh.material;

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

        const pointsMaterial = new this.THREE.PointsMaterial({
          color: 0x00ffaa,
          size: 0.02
        });

        this.mesh = new this.THREE.Points(geometry, pointsMaterial);
        this.scene!.add(this.mesh);
        break;
    }
  },

  rotateCamera(axis?: string, angle: number = 0.1) {
    if (!this.camera || !this.THREE) return;

    switch (axis) {
      case 'x':
        this.camera.position.applyAxisAngle(new this.THREE.Vector3(1, 0, 0), angle);
        break;
      case 'y':
        this.camera.position.applyAxisAngle(new this.THREE.Vector3(0, 1, 0), angle);
        break;
      case 'z':
        this.camera.position.applyAxisAngle(new this.THREE.Vector3(0, 0, 1), angle);
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
    if (!this.camera || !this.THREE) return;

    const direction = new this.THREE.Vector3();
    this.camera.getWorldDirection(direction);
    this.camera.position.addScaledVector(direction, distance);
  },

  cycleRenderMode() {
    if (!this.mesh || !this.THREE) return;

    const currentMaterial = this.mesh.material;

    // Check material type by properties instead of instanceof
    if (currentMaterial.isMeshPhongMaterial || currentMaterial.type === 'MeshPhongMaterial') {
      if (currentMaterial.wireframe) {
        // Wireframe -> Points
        this.setRenderMode('points');
      } else {
        // Solid -> Wireframe
        this.setRenderMode('wireframe');
      }
    } else if (currentMaterial.isPointsMaterial || currentMaterial.type === 'PointsMaterial') {
      // Points -> Solid
      this.setRenderMode('solid');
    }
  },

  positionCanvas() {
    // Extract component ID from wrapper
    const wrapperId = this.el.id;
    const componentId = wrapperId.replace('stl-viewer-wrapper-', '');

    const canvasContainer = this.el.querySelector(`#stl-canvas-container-${componentId}`) as HTMLElement;
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
        this.mesh.material.dispose();
      }
    }

    console.log('STL Viewer destroyed');
  }
};

export default {
  STLViewerHook
};
