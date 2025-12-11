// ========================================
//   Interview Question Bank - Interactive Features
// ========================================

// Initialize all features when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initSmoothScroll();
    initCardAnimations();
    initProgressTracking();
    initSearchEnhancements();
    initKeyboardShortcuts();
    initTooltips();
    addCopyButtons();
});

// ========================================
//   TOAST NOTIFICATIONS
// ========================================
function showToast(message, type = 'success') {
    const toastContainer = getOrCreateToastContainer();

    const toast = document.createElement('div');
    toast.className = `toast-notification toast-${type} fade-in`;

    const icon = type === 'success' ? '✓' : type === 'error' ? '✗' : 'ℹ';
    toast.innerHTML = `
        <span class="toast-icon">${icon}</span>
        <span class="toast-message">${message}</span>
    `;

    toastContainer.appendChild(toast);

    // Auto-remove after 3 seconds
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(-20px)';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

function getOrCreateToastContainer() {
    let container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        container.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 9999;
            display: flex;
            flex-direction: column;
            gap: 10px;
        `;
        document.body.appendChild(container);
    }
    return container;
}

// ========================================
//   FAVORITE & PROGRESS TOGGLES
// ========================================
async function toggleFavorite(questionId) {
    try {
        const response = await fetch(`/Questions/ToggleFavorite/${questionId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'RequestVerificationToken': getAntiForgeryToken()
            }
        });

        if (response.ok) {
            const result = await response.json();
            updateFavoriteButton(questionId, result.isFavorite);
            showToast(result.isFavorite ? 'Added to favorites!' : 'Removed from favorites');
        } else {
            showToast('Please sign in to use favorites', 'error');
        }
    } catch (error) {
        console.error('Error toggling favorite:', error);
        showToast('An error occurred', 'error');
    }
}

async function toggleCompleted(questionId) {
    try {
        const response = await fetch(`/Questions/ToggleCompleted/${questionId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'RequestVerificationToken': getAntiForgeryToken()
            }
        });

        if (response.ok) {
            const result = await response.json();
            updateCompletedButton(questionId, result.isCompleted);
            updateProgressBar();
            showToast(result.isCompleted ? 'Marked as completed!' : 'Marked as incomplete');
        } else {
            showToast('Please sign in to track progress', 'error');
        }
    } catch (error) {
        console.error('Error toggling completed:', error);
        showToast('An error occurred', 'error');
    }
}

function updateFavoriteButton(questionId, isFavorite) {
    const btn = document.querySelector(`[data-favorite-id="${questionId}"]`);
    if (btn) {
        btn.innerHTML = isFavorite ? '<i class="fas fa-star"></i> Favorited' : '<i class="far fa-star"></i> Favorite';
        btn.classList.toggle('active', isFavorite);
    }
}

function updateCompletedButton(questionId, isCompleted) {
    const btn = document.querySelector(`[data-completed-id="${questionId}"]`);
    if (btn) {
        btn.innerHTML = isCompleted ? '<i class="fas fa-check-circle"></i> Completed' : '<i class="far fa-circle"></i> Mark Complete';
        btn.classList.toggle('active', isCompleted);
    }
}

function getAntiForgeryToken() {
    const token = document.querySelector('input[name="__RequestVerificationToken"]');
    return token ? token.value : '';
}

// ========================================
//   SMOOTH SCROLLING
// ========================================
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            if (href !== '#') {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });
                }
            }
        });
    });
}

// ========================================
//   CARD ANIMATIONS (Intersection Observer)
// ========================================
function initCardAnimations() {
    const cards = document.querySelectorAll('.card, .question-item');

    if (cards.length === 0) return;

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in');
                observer.unobserve(entry.target);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '50px'
    });

    cards.forEach((card, index) => {
        card.style.opacity = '0';
        // Stagger animation delay
        const delay = Math.min(index * 0.1, 0.5);
        card.style.animationDelay = `${delay}s`;
        observer.observe(card);
    });
}

// ========================================
//   PROGRESS TRACKING
// ========================================
function updateProgressBar() {
    const progressBar = document.querySelector('.progress-bar');
    if (!progressBar) return;

    fetch('/Questions/GetProgress')
        .then(response => response.json())
        .then(data => {
            const percentage = data.percentage || 0;
            progressBar.style.width = `${percentage}%`;
            progressBar.setAttribute('aria-valuenow', percentage);
            progressBar.textContent = `${percentage}%`;
        })
        .catch(error => console.error('Error updating progress:', error));
}

function initProgressTracking() {
    updateProgressBar();
}

// ========================================
//   SEARCH ENHANCEMENTS
// ========================================
function initSearchEnhancements() {
    const searchInput = document.querySelector('.search-input, input[type="search"]');
    if (!searchInput) return;

    // Add search icon animation
    searchInput.addEventListener('focus', function() {
        this.parentElement?.classList.add('search-focused');
    });

    searchInput.addEventListener('blur', function() {
        this.parentElement?.classList.remove('search-focused');
    });

    // Live search filtering (client-side for better UX)
    let debounceTimer;
    searchInput.addEventListener('input', function(e) {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            filterQuestions(e.target.value);
        }, 300);
    });
}

function filterQuestions(searchTerm) {
    const questionCards = document.querySelectorAll('.question-card, .card');
    const term = searchTerm.toLowerCase().trim();

    if (term === '') {
        questionCards.forEach(card => {
            card.style.display = '';
            card.classList.remove('filtered-out');
        });
        return;
    }

    questionCards.forEach(card => {
        const title = card.querySelector('h5, h4, h3, .card-title')?.textContent.toLowerCase() || '';
        const content = card.textContent.toLowerCase();

        if (title.includes(term) || content.includes(term)) {
            card.style.display = '';
            card.classList.remove('filtered-out');
            card.classList.add('filtered-in');
        } else {
            card.style.display = 'none';
            card.classList.add('filtered-out');
            card.classList.remove('filtered-in');
        }
    });
}

// ========================================
//   KEYBOARD SHORTCUTS
// ========================================
function initKeyboardShortcuts() {
    document.addEventListener('keydown', function(e) {
        // Ctrl/Cmd + K: Focus search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            const searchInput = document.querySelector('.search-input, input[type="search"]');
            if (searchInput) {
                searchInput.focus();
                searchInput.select();
            }
        }

        // Ctrl/Cmd + /: Show keyboard shortcuts help
        if ((e.ctrlKey || e.metaKey) && e.key === '/') {
            e.preventDefault();
            showKeyboardShortcutsHelp();
        }

        // Arrow keys for question navigation
        if (e.key === 'ArrowLeft') {
            const prevBtn = document.querySelector('.btn-prev-question');
            if (prevBtn && !isInputFocused()) {
                prevBtn.click();
            }
        }

        if (e.key === 'ArrowRight') {
            const nextBtn = document.querySelector('.btn-next-question');
            if (nextBtn && !isInputFocused()) {
                nextBtn.click();
            }
        }
    });
}

function isInputFocused() {
    const activeElement = document.activeElement;
    return activeElement.tagName === 'INPUT' ||
           activeElement.tagName === 'TEXTAREA' ||
           activeElement.isContentEditable;
}

function showKeyboardShortcutsHelp() {
    const helpText = `Keyboard Shortcuts:
• Ctrl/Cmd + K: Focus search
• Ctrl/Cmd + /: Show this help
• ← →: Navigate between questions`;
    showToast(helpText, 'info');
}

// ========================================
//   TOOLTIPS INITIALIZATION
// ========================================
function initTooltips() {
    // Initialize Bootstrap tooltips if available
    if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function (tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    }
}

// ========================================
//   COPY CODE BUTTONS
// ========================================
function addCopyButtons() {
    document.querySelectorAll('pre code').forEach((block) => {
        const button = document.createElement('button');
        button.className = 'btn btn-sm btn-outline-secondary copy-code-btn';
        button.innerHTML = '<i class="fas fa-copy"></i> Copy';
        button.style.cssText = 'position: absolute; top: 10px; right: 10px;';

        button.addEventListener('click', async () => {
            try {
                await navigator.clipboard.writeText(block.textContent);
                button.innerHTML = '<i class="fas fa-check"></i> Copied!';
                setTimeout(() => {
                    button.innerHTML = '<i class="fas fa-copy"></i> Copy';
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
                showToast('Failed to copy code', 'error');
            }
        });

        const pre = block.parentElement;
        if (pre && pre.tagName === 'PRE') {
            pre.style.position = 'relative';
            pre.appendChild(button);
        }
    });
}

// ========================================
//   PRINT QUESTION FEATURE
// ========================================
function printQuestion() {
    window.print();
}

// ========================================
//   EXPORT TO PDF (future feature)
// ========================================
function exportToPDF(questionId) {
    showToast('Export to PDF feature coming soon!', 'info');
}

// Add CSS for toast notifications dynamically
const toastStyles = document.createElement('style');
toastStyles.textContent = `
.toast-notification {
    background: white;
    padding: 1rem 1.5rem;
    border-radius: 10px;
    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
    display: flex;
    align-items: center;
    gap: 0.75rem;
    min-width: 250px;
    transition: all 0.3s ease;
}

.toast-success {
    border-left: 4px solid #10b981;
}

.toast-error {
    border-left: 4px solid #ef4444;
}

.toast-info {
    border-left: 4px solid #3b82f6;
}

.toast-icon {
    font-size: 1.25rem;
    font-weight: bold;
}

.toast-success .toast-icon { color: #10b981; }
.toast-error .toast-icon { color: #ef4444; }
.toast-info .toast-icon { color: #3b82f6; }

.toast-message {
    flex: 1;
    color: #1f2937;
    white-space: pre-line;
}

.copy-code-btn {
    opacity: 0.7;
    transition: opacity 0.3s ease;
}

.copy-code-btn:hover {
    opacity: 1;
}

pre {
    position: relative;
}

pre:hover .copy-code-btn {
    opacity: 1;
}
`;
document.head.appendChild(toastStyles);

console.log('Interview Question Bank - Interactive features loaded successfully!');
