// ==================== Global Variables ====================
let allQuestions = [];
let currentPage = 1;
let questionsPerPage = 10;
let filteredQuestions = [];
let currentQuestionIndex = 0;

// ==================== Initialization ====================
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
    loadQuestions();
});

function initializeApp() {
    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Active navigation link highlighting
    window.addEventListener('scroll', updateActiveNavLink);
}

function setupEventListeners() {
    // Search functionality
    const searchInput = document.getElementById('searchInput');
    if (searchInput) {
        searchInput.addEventListener('input', debounce(handleSearch, 300));
    }

    // Filter dropdowns
    const sectionFilter = document.getElementById('sectionFilter');
    const difficultyFilter = document.getElementById('difficultyFilter');

    if (sectionFilter) {
        sectionFilter.addEventListener('change', handleFilters);
    }

    if (difficultyFilter) {
        difficultyFilter.addEventListener('change', handleFilters);
    }

    // Mobile menu toggle
    const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
    const navMenu = document.querySelector('.nav-menu');

    if (mobileMenuToggle && navMenu) {
        mobileMenuToggle.addEventListener('click', () => {
            navMenu.classList.toggle('active');
        });
    }

    // Close modal when clicking outside
    const modal = document.getElementById('questionModal');
    if (modal) {
        modal.addEventListener('click', function(e) {
            if (e.target === modal) {
                closeModal();
            }
        });
    }
}

// ==================== Navigation ====================
function updateActiveNavLink() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');

    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.pageYOffset >= (sectionTop - 100)) {
            current = section.getAttribute('id');
        }
    });

    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
}

function loadSection(sectionName) {
    // Filter questions by section
    document.getElementById('sectionFilter').value = sectionName;
    handleFilters();

    // Scroll to questions section
    document.getElementById('questions').scrollIntoView({
        behavior: 'smooth'
    });
}

// ==================== Questions Loading ====================
function loadQuestions() {
    // Load questions from the questions-data.js file
    if (typeof questionsDatabase !== 'undefined') {
        allQuestions = questionsDatabase;
        filteredQuestions = [...allQuestions];
        displayQuestions();
        setupPagination();
    } else {
        // If questions data not loaded, show placeholder
        displayPlaceholderQuestions();
    }
}

function displayPlaceholderQuestions() {
    const questionsList = document.getElementById('questionsList');
    if (!questionsList) return;

    const sections = [
        { name: 'Advanced .NET & ASP.NET Core', range: '91-99', section: 'dotnet-advanced' },
        { name: 'Azure Cloud Services', range: '100-120', section: 'azure-cloud' },
        { name: 'DevOps & CI/CD', range: '121-130', section: 'devops' },
        { name: 'Microservices Basics', range: '131-140', section: 'microservices-basic' },
        { name: 'Advanced Microservices', range: '141-171', section: 'microservices-advanced' },
        { name: 'SQL Server & Database', range: '172-200', section: 'sql-database' }
    ];

    let html = '';
    sections.forEach(section => {
        html += `
            <div class="question-item" onclick="showSectionInfo('${section.section}')">
                <span class="question-number">Q${section.range}</span>
                <span class="question-title">${section.name}</span>
                <div class="question-tags">
                    <span class="tag tag-intermediate">Multiple Questions</span>
                </div>
            </div>
        `;
    });

    questionsList.innerHTML = html;
}

function showSectionInfo(section) {
    const sectionInfo = {
        'dotnet-advanced': {
            title: 'Advanced .NET & ASP.NET Core (Q91-Q99)',
            description: 'Covers Dependency Injection, Middleware, Authentication, Async/Await, Entity Framework Core, and Performance Optimization.'
        },
        'azure-cloud': {
            title: 'Azure Cloud Services (Q100-Q120)',
            description: 'Includes Azure Service Bus, Event Hub, Event Grid, Redis Cache, Azure SQL, Cosmos DB, and more.'
        },
        'devops': {
            title: 'DevOps & CI/CD (Q121-Q130)',
            description: 'Azure DevOps, CI/CD Pipelines, Docker, Kubernetes, Infrastructure as Code.'
        },
        'microservices-basic': {
            title: 'Microservices Basics (Q131-Q140)',
            description: 'Microservices Architecture, API Gateway, Service Discovery, Communication Patterns.'
        },
        'microservices-advanced': {
            title: 'Advanced Microservices (Q141-Q171)',
            description: 'CQRS, Event Sourcing, Saga Pattern, Circuit Breaker, Service Mesh, and more.'
        },
        'sql-database': {
            title: 'SQL Server & Database (Q172-Q200)',
            description: 'SQL Joins, Indexes, Stored Procedures, Triggers, Transactions, Query Optimization, Performance Tuning.'
        }
    };

    const info = sectionInfo[section];
    if (info) {
        showModal(info.title, `
            <p style="font-size: 1.1rem; line-height: 1.8;">${info.description}</p>
            <h3 style="margin-top: 2rem;">What You'll Learn:</h3>
            <ul style="line-height: 2; margin-left: 1.5rem;">
                <li>Comprehensive explanations with real-world examples</li>
                <li>Production-ready C# code samples</li>
                <li>Visual diagrams and comparisons</li>
                <li>Best practices and anti-patterns</li>
                <li>Integration examples with modern .NET</li>
            </ul>
            <p style="margin-top: 2rem; padding: 1rem; background: #F3F4F6; border-radius: 8px;">
                <strong>Note:</strong> All questions are available in the markdown files in the Q-A folder.
                This website interface is designed to help you navigate and explore the questions efficiently.
            </p>
        `);
    }
}

function displayQuestions() {
    const questionsList = document.getElementById('questionsList');
    if (!questionsList) return;

    const startIndex = (currentPage - 1) * questionsPerPage;
    const endIndex = startIndex + questionsPerPage;
    const questionsToDisplay = filteredQuestions.slice(startIndex, endIndex);

    if (questionsToDisplay.length === 0) {
        questionsList.innerHTML = `
            <div style="text-align: center; padding: 3rem; color: #6B7280;">
                <i class="fas fa-search" style="font-size: 3rem; margin-bottom: 1rem;"></i>
                <p style="font-size: 1.2rem;">No questions found matching your criteria.</p>
                <p>Try adjusting your search or filters.</p>
            </div>
        `;
        return;
    }

    let html = '';
    questionsToDisplay.forEach((question, index) => {
        html += `
            <div class="question-item" onclick="showQuestion(${startIndex + index})">
                <span class="question-number">Q${question.number}</span>
                <span class="question-title">${question.title}</span>
                <div class="question-tags">
                    <span class="tag tag-${question.difficulty}">${question.difficulty}</span>
                </div>
            </div>
        `;
    });

    questionsList.innerHTML = html;
}

function setupPagination() {
    const pagination = document.getElementById('pagination');
    if (!pagination) return;

    const totalPages = Math.ceil(filteredQuestions.length / questionsPerPage);

    let html = '';

    // Previous button
    html += `
        <button onclick="changePage(${currentPage - 1})" ${currentPage === 1 ? 'disabled' : ''}>
            <i class="fas fa-chevron-left"></i> Previous
        </button>
    `;

    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= currentPage - 2 && i <= currentPage + 2)) {
            html += `
                <button class="${i === currentPage ? 'active' : ''}" onclick="changePage(${i})">
                    ${i}
                </button>
            `;
        } else if (i === currentPage - 3 || i === currentPage + 3) {
            html += `<button disabled>...</button>`;
        }
    }

    // Next button
    html += `
        <button onclick="changePage(${currentPage + 1})" ${currentPage === totalPages ? 'disabled' : ''}>
            Next <i class="fas fa-chevron-right"></i>
        </button>
    `;

    pagination.innerHTML = html;
}

function changePage(page) {
    const totalPages = Math.ceil(filteredQuestions.length / questionsPerPage);
    if (page < 1 || page > totalPages) return;

    currentPage = page;
    displayQuestions();
    setupPagination();

    // Scroll to top of questions list
    document.getElementById('questionsList').scrollIntoView({
        behavior: 'smooth',
        block: 'start'
    });
}

// ==================== Search and Filter ====================
function handleSearch(event) {
    const searchTerm = event.target.value.toLowerCase();

    filteredQuestions = allQuestions.filter(question =>
        question.title.toLowerCase().includes(searchTerm) ||
        question.content.toLowerCase().includes(searchTerm) ||
        question.number.toString().includes(searchTerm)
    );

    // Apply other filters
    applyFilters();

    currentPage = 1;
    displayQuestions();
    setupPagination();
}

function handleFilters() {
    applyFilters();
    currentPage = 1;
    displayQuestions();
    setupPagination();
}

function applyFilters() {
    const sectionFilter = document.getElementById('sectionFilter').value;
    const difficultyFilter = document.getElementById('difficultyFilter').value;
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();

    filteredQuestions = allQuestions.filter(question => {
        const matchesSection = sectionFilter === 'all' || question.section === sectionFilter;
        const matchesDifficulty = difficultyFilter === 'all' || question.difficulty === difficultyFilter;
        const matchesSearch = searchTerm === '' ||
            question.title.toLowerCase().includes(searchTerm) ||
            question.content.toLowerCase().includes(searchTerm) ||
            question.number.toString().includes(searchTerm);

        return matchesSection && matchesDifficulty && matchesSearch;
    });
}

// ==================== Modal Functions ====================
function showQuestion(index) {
    currentQuestionIndex = index;
    const question = filteredQuestions[index];

    if (!question) return;

    const modalTitle = document.getElementById('modalQuestionTitle');
    const modalBody = document.getElementById('modalQuestionBody');
    const modal = document.getElementById('questionModal');

    modalTitle.textContent = `Q${question.number}: ${question.title}`;
    modalBody.innerHTML = formatQuestionContent(question.content);

    // Highlight code blocks
    modalBody.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightElement(block);
    });

    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function showModal(title, content) {
    const modalTitle = document.getElementById('modalQuestionTitle');
    const modalBody = document.getElementById('modalQuestionBody');
    const modal = document.getElementById('questionModal');

    modalTitle.textContent = title;
    modalBody.innerHTML = content;

    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    const modal = document.getElementById('questionModal');
    modal.classList.remove('active');
    document.body.style.overflow = 'auto';
}

function previousQuestion() {
    if (currentQuestionIndex > 0) {
        showQuestion(currentQuestionIndex - 1);
    }
}

function nextQuestion() {
    if (currentQuestionIndex < filteredQuestions.length - 1) {
        showQuestion(currentQuestionIndex + 1);
    }
}

function formatQuestionContent(content) {
    // Convert markdown-like content to HTML
    let html = content;

    // Convert headers
    html = html.replace(/### (.*?)$/gm, '<h3>$1</h3>');
    html = html.replace(/## (.*?)$/gm, '<h2>$1</h2>');

    // Convert code blocks
    html = html.replace(/```(\w+)?\n([\s\S]*?)```/g, function(match, lang, code) {
        const language = lang || 'csharp';
        return `<pre><code class="language-${language}">${escapeHtml(code.trim())}</code></pre>`;
    });

    // Convert inline code
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Convert bold
    html = html.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');

    // Convert lists
    html = html.replace(/^\* (.*?)$/gm, '<li>$1</li>');
    html = html.replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>');

    // Convert line breaks
    html = html.replace(/\n\n/g, '</p><p>');
    html = '<p>' + html + '</p>';

    return html;
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

// ==================== Utility Functions ====================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ==================== Keyboard Shortcuts ====================
document.addEventListener('keydown', function(e) {
    const modal = document.getElementById('questionModal');
    if (!modal.classList.contains('active')) return;

    // Escape to close modal
    if (e.key === 'Escape') {
        closeModal();
    }

    // Arrow keys to navigate
    if (e.key === 'ArrowLeft') {
        previousQuestion();
    }
    if (e.key === 'ArrowRight') {
        nextQuestion();
    }
});

// ==================== Export Functions for Global Access ====================
window.loadSection = loadSection;
window.showQuestion = showQuestion;
window.showSectionInfo = showSectionInfo;
window.closeModal = closeModal;
window.previousQuestion = previousQuestion;
window.nextQuestion = nextQuestion;
window.changePage = changePage;
