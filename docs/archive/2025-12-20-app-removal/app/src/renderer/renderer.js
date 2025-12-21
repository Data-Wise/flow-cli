// Renderer process - Frontend JavaScript
console.log('Renderer process loaded');

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  initializeApp();
});

function initializeApp() {
  // Display system information
  displaySystemInfo();

  // Set up event listeners
  setupEventListeners();

  // Add welcome animation
  animateWelcome();

  console.log('App initialized successfully');
}

function displaySystemInfo() {
  if (window.electronAPI) {
    // Display platform
    const platformEl = document.getElementById('platform');
    if (platformEl) {
      const platform = window.electronAPI.platform;
      const platformName = {
        'darwin': 'macOS',
        'win32': 'Windows',
        'linux': 'Linux'
      }[platform] || platform;
      platformEl.textContent = platformName;
    }

    // Display versions
    if (window.electronAPI.versions) {
      const { node, chrome, electron } = window.electronAPI.versions;

      const nodeEl = document.getElementById('node-version');
      if (nodeEl) nodeEl.textContent = `v${node}`;

      const chromeEl = document.getElementById('chrome-version');
      if (chromeEl) chromeEl.textContent = `v${chrome}`;

      const electronEl = document.getElementById('electron-version');
      if (electronEl) electronEl.textContent = `v${electron}`;
    }
  }
}

function setupEventListeners() {
  // Action buttons
  const actionButtons = document.querySelectorAll('.action-btn');
  actionButtons.forEach(btn => {
    btn.addEventListener('click', handleActionClick);
  });

  // Add hover effects
  const cards = document.querySelectorAll('.workspace-card, .stat-item');
  cards.forEach(card => {
    card.addEventListener('mouseenter', () => {
      card.style.transition = 'all 0.3s ease';
    });
  });
}

function handleActionClick(event) {
  const button = event.currentTarget;
  const btnText = button.querySelector('strong');

  if (!btnText) return;

  const action = btnText.textContent.trim();

  // Visual feedback
  button.style.transform = 'scale(0.95)';
  setTimeout(() => {
    button.style.transform = '';
  }, 150);

  // Log action (in future, will trigger actual commands)
  console.log(`Action clicked: ${action}`);

  // Show notification
  showNotification(`Action: ${action}`, 'Coming in P5C!');
}

function animateWelcome() {
  const sections = document.querySelectorAll('section');
  sections.forEach((section, index) => {
    section.style.animationDelay = `${index * 0.1}s`;
  });
}

function showNotification(title, message) {
  // Simple console notification for now
  // In P5C, will show actual desktop notifications
  console.log(`📢 ${title}: ${message}`);
}

// Error handling
window.addEventListener('error', (event) => {
  console.error('Renderer error:', event.error);
});

window.addEventListener('unhandledrejection', (event) => {
  console.error('Unhandled promise rejection:', event.reason);
});
