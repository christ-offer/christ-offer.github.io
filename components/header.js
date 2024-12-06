// Web component
class Header extends HTMLElement {
  connectedCallback() {
    this.innerHTML = `
        <div class="ascii-logo">
          <svg
            class="responsive-svg"
            viewBox="-200 0 620 180"
            xmlns="http://www.w3.org/2000/svg"
            preserveAspectRatio="xMidYMid meet"
          >
            <!-- All your existing SVG content stays exactly the same -->
            <!-- Monitor frame -->
            <rect
              x="-10"
              y="10"
              width="240"
              height="140"
              rx="8"
              fill="#2a2a2a"
              stroke="#3a3a3a"
              stroke-width="4"
            />
            <!-- Screen -->
            <rect x="0" y="20" width="220" height="120" rx="4" fill="#1a1a1a" />

            <!-- Terminal content -->
            <g>
              <!-- Command prompt -->
              <text x="35" y="45" font-family="monospace" font-size="14">
                root@chris$ ls
              </text>

              <!-- Animated directory listing -->
              <g font-family="monospace" font-size="14">
                <a href="index.html">
                  <text x="35" y="65">
                    <tspan class="${this.hasAttribute('home') ? 'active' : ''}">drwxr-xr-x Home/</tspan>
                    <animate
                      attributeName="opacity"
                      values="0;1"
                      dur="0.1s"
                      begin="0.1s"
                      fill="freeze"
                    />
                  </text>
                </a>
                <a href="blog.html">
                  <text x="35" y="85">
                    <tspan class="${this.hasAttribute('blog') ? 'active' : ''}">drwxr-xr-x Blog/</tspan>
                    <animate
                      attributeName="opacity"
                      values="0;1"
                      dur="0.1s"
                      begin="0.2s"
                      fill="freeze"
                    />
                  </text>
                </a>
                <a href="photos.html">
                  <text x="35" y="105">
                    <tspan class="${this.hasAttribute('photos') ? 'active' : ''}">drwxr-xr-x Photos/</tspan>
                    <animate
                      attributeName="opacity"
                      values="0;1"
                      dur="0.1s"
                      begin="0.3s"
                      fill="freeze"
                    />
                  </text>
                </a>
                <a href="projects.html">
                  <text x="35" y="125">
                    <tspan class="${this.hasAttribute('projects') ? 'active' : ''}">drwxr-xr-x Projects/</tspan>
                    <animate
                      attributeName="opacity"
                      values="0;1"
                      dur="0.1s"
                      begin="0.4s"
                      fill="freeze"
                    />
                  </text>
                </a>
              </g>
            </g>

            <!-- Stand -->
            <path d="M80 150 L140 150 L130 160 L90 160 Z" fill="#2a2a2a" />

            <!-- Extended desk plate -->
            <rect x="-250" y="160" width="800" height="20" fill="#8B4513" />

            <!-- Coffee Cup with animations stays the same -->
            <g transform="translate(250, 159)">
              <!-- Cup body -->
              <path
                d="M0,0 L0,-20 Q0,-25 5,-25 L20,-25 Q25,-25 25,-20 L25,0 Z"
                fill="#ffffff"
              />
              <!-- Handle -->
              <path
                d="M25,-15 Q30,-15 30,-10 Q30,-5 25,-5"
                fill="none"
                stroke="#ffffff"
                stroke-width="2"
              />

              <!-- Animated smoke -->
              <g fill="none" stroke="#cccccc" stroke-width="1.5">
                <path d="M8,-30 Q13,-35 8,-40">
                  <animate
                    attributeName="d"
                    values="M8,-30 Q13,-35 8,-40;
                           M8,-30 Q3,-35 8,-40;
                           M8,-30 Q13,-35 8,-40"
                    dur="3s"
                    repeatCount="indefinite"
                  />
                  <animate
                    attributeName="opacity"
                    values="0.8;0;0.8"
                    dur="3s"
                    repeatCount="indefinite"
                  />
                </path>
                <path d="M15,-30 Q20,-38 15,-45">
                  <animate
                    attributeName="d"
                    values="M15,-30 Q20,-38 15,-45;
                           M15,-30 Q10,-38 15,-45;
                           M15,-30 Q20,-38 15,-45"
                    dur="3s"
                    begin="1s"
                    repeatCount="indefinite"
                  />
                  <animate
                    attributeName="opacity"
                    values="0.8;0;0.8"
                    dur="3s"
                    begin="1s"
                    repeatCount="indefinite"
                  />
                </path>
                <path d="M20,-30 Q25,-36 20,-42">
                  <animate
                    attributeName="d"
                    values="M20,-30 Q25,-36 20,-42;
                           M20,-30 Q15,-36 20,-42;
                           M20,-30 Q25,-36 20,-42"
                    dur="3s"
                    begin="2s"
                    repeatCount="indefinite"
                  />
                  <animate
                    attributeName="opacity"
                    values="0.8;0;0.8"
                    dur="3s"
                    begin="2s"
                    repeatCount="indefinite"
                  />
                </path>
              </g>
            </g>
          </svg>
        </div>
    `;
  }
}

customElements.define("header-component", Header);
