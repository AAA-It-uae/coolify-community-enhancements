<style>
    #coolify-magnifier-toggle {
        display: none;
        border-color: rgba(99, 102, 241, .20);
        background: rgba(99, 102, 241, .045);
    }
    @media (min-width: 1280px) {
        #coolify-magnifier-toggle { display: inline-flex; }
    }
    #coolify-magnifier-toggle:hover,
    #coolify-magnifier-toggle.is-active {
        color: #6d28d9;
        border-color: rgba(109, 40, 217, .42);
        background: rgba(109, 40, 217, .09);
    }
    #coolify-magnifier-lens {
        position: fixed;
        width: 240px;
        height: 240px;
        border-radius: 9999px;
        overflow: hidden;
        pointer-events: none;
        z-index: 2147483600;
        border: 3px solid rgba(109, 40, 217, .86);
        background: #fff;
        box-shadow: 0 18px 55px rgba(0,0,0,.24), 0 0 0 4px rgba(109,40,217,.12);
        contain: strict;
    }
    #coolify-magnifier-lens::before,
    #coolify-magnifier-lens::after {
        content: '';
        position: absolute;
        z-index: 2147483602;
        pointer-events: none;
        background: rgba(109, 40, 217, .42);
    }
    #coolify-magnifier-lens::before {
        width: 18px;
        height: 1px;
        left: calc(50% - 9px);
        top: 50%;
    }
    #coolify-magnifier-lens::after {
        width: 1px;
        height: 18px;
        left: 50%;
        top: calc(50% - 9px);
    }
    #coolify-magnifier-lens .coolify-magnifier-stage {
        position: absolute;
        inset: 0;
        overflow: hidden;
        pointer-events: none;
    }
    html.coolify-magnifier-active,
    html.coolify-magnifier-active * {
        cursor: none !important;
    }
</style>

<button id="coolify-magnifier-toggle" type="button"
    class="size-8 shrink-0 items-center justify-center rounded-lg border text-neutral-500 transition-colors dark:text-fg-dim"
    title="Magnifier: click to activate, click a target to select it, Esc to cancel"
    aria-label="Activate page magnifier" aria-pressed="false" data-coolify-magnifier-control>
    <svg viewBox="0 0 24 24" class="size-4" fill="none" stroke="currentColor" stroke-width="1.8"
        stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <circle cx="11" cy="11" r="6.5"></circle>
        <path d="m16 16 4.25 4.25"></path>
        <path d="M8.5 11h5M11 8.5v5"></path>
    </svg>
</button>

<script>
(() => {
    if (window.__coolifyMagnifierInstalled) return;
    window.__coolifyMagnifierInstalled = true;

    const ZOOM = 1.85;
    const SIZE = 240;
    const RADIUS = SIZE / 2;
    let active = false;
    let lens = null;
    let snapshot = null;
    let lastX = Math.round(window.innerWidth / 2);
    let lastY = Math.round(window.innerHeight / 2);
    let raf = 0;

    const button = document.getElementById('coolify-magnifier-toggle');
    if (!button) return;

    function sanitizeClone(root) {
        root.querySelectorAll('script, iframe, video, audio').forEach((node) => node.remove());
        root.querySelectorAll('*').forEach((node) => {
            [...node.attributes].forEach((attr) => {
                const name = attr.name.toLowerCase();
                if (
                    name === 'id' ||
                    name.startsWith('wire:') ||
                    name.startsWith('x-') ||
                    name.startsWith('@') ||
                    name.startsWith(':') ||
                    name.startsWith('on')
                ) {
                    node.removeAttribute(attr.name);
                }
            });
            node.setAttribute('tabindex', '-1');
        });
    }

    function buildSnapshot() {
        const root = document.createElement('div');
        root.className = document.body.className;
        root.setAttribute('aria-hidden', 'true');
        root.style.position = 'absolute';
        root.style.left = '0';
        root.style.top = '0';
        root.style.width = `${Math.max(document.documentElement.scrollWidth, window.innerWidth)}px`;
        root.style.minHeight = `${Math.max(document.documentElement.scrollHeight, window.innerHeight)}px`;
        root.style.margin = '0';
        root.style.padding = '0';
        root.style.pointerEvents = 'none';
        root.style.transformOrigin = '0 0';
        root.style.background = getComputedStyle(document.body).background;
        root.style.color = getComputedStyle(document.body).color;

        [...document.body.children].forEach((child) => {
            if (child.id === 'coolify-magnifier-lens') return;
            const copy = child.cloneNode(true);
            sanitizeClone(copy);
            root.appendChild(copy);
        });
        return root;
    }

    function sourceUsesViewportCoordinates(x, y) {
        let node = document.elementFromPoint(x, y);
        while (node && node !== document.body) {
            const pos = getComputedStyle(node).position;
            if (pos === 'fixed' || pos === 'sticky') return true;
            node = node.parentElement;
        }
        return false;
    }

    function renderLens() {
        raf = 0;
        if (!active || !lens || !snapshot) return;
        lens.style.left = `${lastX - RADIUS}px`;
        lens.style.top = `${lastY - RADIUS}px`;
        const viewportAnchored = sourceUsesViewportCoordinates(lastX, lastY);
        const sourceX = lastX + (viewportAnchored ? 0 : window.scrollX);
        const sourceY = lastY + (viewportAnchored ? 0 : window.scrollY);
        const tx = RADIUS - sourceX * ZOOM;
        const ty = RADIUS - sourceY * ZOOM;
        snapshot.style.transform = `translate3d(${tx}px, ${ty}px, 0) scale(${ZOOM})`;
    }

    function requestRender() {
        if (!raf) raf = requestAnimationFrame(renderLens);
    }

    function activate(x, y) {
        if (active) return;
        active = true;
        lastX = x;
        lastY = y;
        lens = document.createElement('div');
        lens.id = 'coolify-magnifier-lens';
        lens.setAttribute('aria-hidden', 'true');
        const stage = document.createElement('div');
        stage.className = 'coolify-magnifier-stage';
        snapshot = buildSnapshot();
        stage.appendChild(snapshot);
        lens.appendChild(stage);
        document.body.appendChild(lens);
        document.documentElement.classList.add('coolify-magnifier-active');
        button.classList.add('is-active');
        button.setAttribute('aria-pressed', 'true');
        button.setAttribute('aria-label', 'Deactivate page magnifier');
        requestRender();
    }

    function deactivate() {
        if (!active) return;
        active = false;
        if (raf) cancelAnimationFrame(raf);
        raf = 0;
        lens?.remove();
        lens = null;
        snapshot = null;
        document.documentElement.classList.remove('coolify-magnifier-active');
        button.classList.remove('is-active');
        button.setAttribute('aria-pressed', 'false');
        button.setAttribute('aria-label', 'Activate page magnifier');
    }

    button.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        if (active) {
            deactivate();
        } else {
            activate(event.clientX || button.getBoundingClientRect().left, event.clientY || button.getBoundingClientRect().bottom);
        }
    });

    document.addEventListener('pointermove', (event) => {
        if (!active) return;
        lastX = event.clientX;
        lastY = event.clientY;
        requestRender();
    }, { passive: true });

    document.addEventListener('click', (event) => {
        if (!active || button.contains(event.target)) return;
        setTimeout(deactivate, 0);
    }, true);

    document.addEventListener('keydown', (event) => {
        if (active && event.key === 'Escape') {
            event.preventDefault();
            deactivate();
        }
    });

    window.addEventListener('scroll', requestRender, { passive: true });
    window.addEventListener('resize', () => {
        if (active) deactivate();
    }, { passive: true });
})();
</script>
