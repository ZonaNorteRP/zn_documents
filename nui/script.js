let playerData = {};
let currentQuestionIndex = 0;
let userAnswers = [];
let testQuestions = [];
let isConsulting = false;

// Initialization
document.addEventListener('DOMContentLoaded', () => {
    // Navigation setup
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', () => {
            const page = item.getAttribute('data-page');
            console.log('[ZN-DOCUMENTS] Sidebar Nav clicked:', page);
            if (page === 'consultation') resetConsultationPage();
            if (page) navigateToPage(page);
        });
    });

    document.querySelectorAll('.menu-card').forEach(item => {
        item.addEventListener('click', () => {
            const page = item.getAttribute('data-page');
            if (page === 'consultation') resetConsultationPage();
            if (page) navigateToPage(page);
        });
    });

    document.querySelectorAll('.back-btn').forEach(btn => {
        btn.addEventListener('click', () => navigateToPage('home'));
    });

    // CNH Test setup
    document.getElementById('start-test-btn')?.addEventListener('click', startCNHTest);
    
    // Vehicle setup
    document.getElementById('register-vehicle-btn')?.addEventListener('click', startVehicleRegistration);
    
    // Consultation setup
    document.getElementById('consult-btn')?.addEventListener('click', consultVehicle);
    document.getElementById('save-dmv-btn')?.addEventListener('click', saveVehicleManagement);
    
    // ESC to close
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            closeUI();
        }
    });

    // Vehicle Registration Form Setup
    document.getElementById('vehicle-registration-form')?.addEventListener('submit', (e) => {
        e.preventDefault();
        submitRegistration();
    });
});

// NUI Events
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openUI') {
        openUI(data.playerData);
    } else if (data.action === 'closeUI') {
        document.getElementById('detran-container').classList.add('hidden');
        document.getElementById('document-viewer').classList.add('hidden');
    } else if (data.action === 'viewDocument') {
        showPhysicalDocument(data.type, data.data);
    }
});

function showPhysicalDocument(type, data) {
    console.log('[ZN-DOCUMENTS] Showing document:', type, data);
    
    // Esconder Sub-Prefeitura se estiver aberto
    document.getElementById('detran-container').classList.add('hidden');
    
    const viewer = document.getElementById('document-viewer');
    const templates = document.querySelectorAll('.doc-card');
    
    viewer.classList.remove('hidden');
    templates.forEach(t => t.classList.add('hidden'));
    
    if (type === 'cnh') {
        document.getElementById('view-cnh-name').textContent = data.name.toUpperCase();
        document.getElementById('view-cnh-birth').textContent = data.birthdate || 'N/A';
        document.getElementById('view-cnh-cpf').textContent = data.citizenid || '000.000.000-00';
        document.getElementById('cnh-template').classList.remove('hidden');
    } else if (type === 'rg') {
        document.getElementById('view-rg-name').textContent = data.name.toUpperCase();
        document.getElementById('view-rg-number').textContent = data.citizenid || '00.000.000-0';
        document.getElementById('rg-template').classList.remove('hidden');
    } else if (type === 'passport') {
        const names = data.name.split(' ');
        const surname = names.pop() || '';
        const givenNames = names.join(' ');
        
        document.getElementById('view-passport-name').textContent = givenNames.toUpperCase();
        document.getElementById('view-passport-surname').textContent = surname.toUpperCase();
        document.getElementById('view-passport-birth').textContent = data.birthdate || '00/00/0000';
        document.getElementById('view-passport-number').textContent = 'ZN' + (data.citizenid ? data.citizenid.substring(0, 6) : '000000').toUpperCase();
        
        const mrzName = (surname + '<<' + givenNames.replace(/ /g, '<')).padEnd(39, '<').toUpperCase();
        document.getElementById('mrz-name').textContent = mrzName;
        document.getElementById('passport-template').classList.remove('hidden');
    }
}

function closeDocumentViewer() {
    document.getElementById('document-viewer').classList.add('hidden');
    // Se o detran estava aberto antes, talvez queira reabrir, mas geralmente ESC ou clique fora fecha tudo.
    post('closeUI', {});
}

// UI Functions
function openUI(data) {
    playerData = data;
    
    console.log('[ZN-DOCUMENTS] Opening UI with data:', data);
    
    // Show container
    document.getElementById('detran-container').classList.remove('hidden');
    
    // Update header
    document.getElementById('player-name').textContent = data.name || 'Cidadão';
    document.getElementById('player-money').textContent = formatMoney((data.bank || 0) + (data.cash || 0));
    
    // Update CNH status
    updateCNHStatus(data.cnhValidated);
    
    // Initial page
    navigateToPage('home');
    
    // Update stats
    document.getElementById('vehicle-count').textContent = data.vehicleCount || 0;
}

function closeUI() {
    document.getElementById('detran-container').classList.add('hidden');
    document.getElementById('document-viewer').classList.add('hidden');
    post('closeUI', {});
}

function navigateToPage(pageId) {
    console.log('[ZN-DOCUMENTS] Navigating to:', pageId);
    
    // Hard reset all pages visibility
    const allPages = document.querySelectorAll('.page');
    allPages.forEach(p => {
        p.classList.add('hidden');
        p.classList.remove('active');
    });
    
    // Hard reset all nav items
    const allNavItems = document.querySelectorAll('.nav-item');
    allNavItems.forEach(i => i.classList.remove('active'));
    
    // Activate target page
    const targetPage = document.getElementById(`${pageId}-page`);
    if (targetPage) {
        targetPage.classList.remove('hidden');
        targetPage.classList.add('active');
        console.log('[ZN-DOCUMENTS] Page activated:', pageId);
    } else {
        console.error('[ZN-DOCUMENTS] Page not found:', pageId);
    }
    
    // Activate target nav item
    const targetNav = document.querySelector(`.nav-item[data-page="${pageId}"]`);
    if (targetNav) {
        targetNav.classList.add('active');
    }

    // Special page loading logic
    if (pageId === 'vehicles') loadMyVehicles();
    else if (pageId === 'ipva') loadIPVADebts();
    else if (pageId === 'documents') loadDocumentsIssuance();
    else if (pageId === 'cnh') resetCNHPage();
}

function updateCNHStatus(isValidated) {
    const badges = [document.getElementById('home-cnh-status')];
    
    badges.forEach(badge => {
        if (!badge) return;
        if (isValidated) {
            badge.classList.add('validated');
            badge.classList.remove('pending');
            badge.querySelector('.status-text').textContent = 'Validado';
        } else {
            badge.classList.remove('validated');
            badge.classList.add('pending');
            badge.querySelector('.status-text').textContent = 'Pendente';
        }
    });
}

function resetCNHPage() {
    document.getElementById('cnh-initial').classList.remove('hidden');
    document.getElementById('cnh-test-container').classList.add('hidden');
    document.getElementById('test-result-container').classList.add('hidden');
}

// CNH Test Functions (Resumed from previous implementation)
function startCNHTest() {
    post('getCNHQuestions', {}).then(questions => {
        testQuestions = questions;
        currentQuestionIndex = 0;
        userAnswers = [];
        
        document.getElementById('cnh-initial').classList.add('hidden');
        document.getElementById('cnh-test-container').classList.remove('hidden');
        document.getElementById('test-result-container').classList.add('hidden');
        
        showQuestion();
    });
}

function showQuestion() {
    const q = testQuestions[currentQuestionIndex];
    document.getElementById('current-question').textContent = q.question;
    document.getElementById('question-counter').textContent = `Questão ${currentQuestionIndex + 1} de ${testQuestions.length}`;
    document.getElementById('test-progress').style.width = `${(currentQuestionIndex / testQuestions.length) * 100}%`;
    
    const container = document.getElementById('options-container');
    container.innerHTML = q.options.map((opt, i) => `
        <button class="option-btn" onclick="selectOption(${i + 1})">${opt}</button>
    `).join('');
}

function selectOption(index) {
    userAnswers.push(index);
    currentQuestionIndex++;
    
    if (currentQuestionIndex < testQuestions.length) {
        showQuestion();
    } else {
        finishTest();
    }
}

async function finishTest() {
    document.getElementById('cnh-test-container').classList.add('hidden');
    const resultContainer = document.getElementById('test-result-container');
    resultContainer.classList.remove('hidden');
    resultContainer.innerHTML = '<div class="loading">Processando resultado...</div>';
    
    // Enviar respostas para validação segura no servidor
    const payload = testQuestions.map((q, i) => {
        return { question: q.question, answer: userAnswers[i] };
    });

    const result = await post('validateCNH', { answers: payload });
    
    // Para efeito visual, calcular no cliente também (mas quem decide é o servidor)
    let correctCount = 0;
    testQuestions.forEach((q, i) => {
        if (userAnswers[i] === q.correct) correctCount++;
    });
    
    resultContainer.innerHTML = `
        <div class="result-content ${result.success ? 'success' : 'fail'}">
            <div class="result-icon">
                ${result.success ? '<svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>' : '<svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>'}
            </div>
            <h2>${result.success ? 'Parabéns! Você Passou!' : 'Você Não Passou'}</h2>
            <p>${result.message || (result.success ? 'Sua habilitação foi emitida.' : 'Tente novamente mais tarde.')}</p>
            <div class="result-stats">
               <div class="stat-item">
                    <span>Acertos</span>
                    <span>${correctCount} / ${testQuestions.length}</span>
               </div>
            </div>
            <button class="btn btn-primary" onclick="navigateToPage('home')">Voltar ao Início</button>
        </div>
    `;
    
    if (result.success) {
        playerData.cnhValidated = true;
        updateCNHStatus(true);
    }
}

// Vehicle & IPVA & Documents functions
async function loadMyVehicles() {
    const list = document.getElementById('vehicles-list');
    list.innerHTML = '<div class="loading">Carregando...</div>';
    const vehicles = await post('getMyVehicles', {});
    if (!vehicles || vehicles.length === 0) {
        list.innerHTML = '<div class="empty-state"><p>Nenhum veículo encontrado.</p></div>';
        return;
    }
    list.innerHTML = vehicles.map(v => `
        <div class="vehicle-card" data-plate="${v.plate}">
            <div class="vehicle-header">
                <span class="plate-label" title="Clique para copiar" style="cursor: pointer;" onclick="copyPlate('${v.plate}')">${v.plate} <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align: middle; margin-left: 4px;"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg></span>
                <span class="model-label">${v.description}</span>
            </div>
            <div class="vehicle-body">
                <p><b>Proprietário:</b> ${v.owner_name}</p>
                <p><b>Motor:</b> ${v.engine_serial || 'N/A'}</p>
                <p><b>Pneus:</b> ${v.tire_type || 'Standard'}</p>
                <p><b>IPVA:</b> <span class="${v.ipva_debt > 0 ? 'debt' : 'paid'}">${formatMoney(v.ipva_debt)}</span></p>
                <button class="btn btn-primary" style="margin-top: 10px; width: 100%;" onclick="openMyVehicleEdit('${v.plate}', '${v.image_url || ''}', '${v.observations || ''}')">Editar Foto/Obs</button>
            </div>
        </div>
    `).join('');
}

async function startVehicleRegistration() {
    const editContainer = document.getElementById('edit-form-container');
    if (editContainer) editContainer.classList.add('hidden');
    
    const container = document.getElementById('registration-form-container');
    const list = document.getElementById('vehicle-selection-list');
    const form = document.getElementById('manual-form');
    
    container.classList.remove('hidden');
    list.classList.remove('hidden');
    document.getElementById('vehicle-registration-form').classList.add('hidden');
    
    list.innerHTML = '<div class="loading">Buscando veículos não registrados...</div>';
    
    const vehicles = await post('getUnregisteredVehicles', {});
    
    if (!vehicles || vehicles.length === 0) {
        list.innerHTML = '<div class="empty-state"><p>Você não possui veículos pendentes de registro.</p></div>';
        return;
    }
    
    list.innerHTML = vehicles.map(v => `
        <div class="selection-card" onclick="selectVehicleForReg('${v.plate}', '${v.vehicle}')">
            <div class="plate-badge">${v.plate}</div>
            <span class="model-name">${v.vehicle}</span>
            <button class="btn-select">Selecionar</button>
        </div>
    `).join('');
}

window.selectVehicleForReg = function(plate, model) {
    document.getElementById('vehicle-selection-list').classList.add('hidden');
    document.getElementById('vehicle-registration-form').classList.remove('hidden');
    
    document.getElementById('reg-plate').value = plate;
    document.getElementById('reg-owner').value = playerData.name || '';
    document.getElementById('reg-color').value = '';
    document.getElementById('reg-description').value = model;
    document.getElementById('reg-engine').value = '';
    document.getElementById('reg-tires').value = 'Standard';
    document.getElementById('reg-gearbox').value = 'Manual';
};

async function submitRegistration() {
    const data = {
        plate: document.getElementById('reg-plate').value,
        owner_name: document.getElementById('reg-owner').value,
        color: document.getElementById('reg-color').value,
        description: document.getElementById('reg-description').value,
        engine: document.getElementById('reg-engine').value,
        tires: document.getElementById('reg-tires').value,
        gearbox: document.getElementById('reg-gearbox').value
    };
    
    const result = await post('registerVehicle', data);
    if (result.success) {
        showNotification('Veículo registrado com sucesso!', 'success');
        document.getElementById('registration-form-container').classList.add('hidden');
        loadMyVehicles();
        post('getPlayerData', {}).then(data => playerData = data);
    } else {
        showNotification(result.message || 'Erro no registro', 'error');
    }
}

window.cancelRegistration = function() {
    document.getElementById('registration-form-container').classList.add('hidden');
};

async function loadIPVADebts() {
    const list = document.getElementById('ipva-list');
    list.innerHTML = '<div class="loading">Carregando...</div>';
    const debts = await post('getIPVADebts', {});
    
    let total = 0;
    debts.forEach(d => total += d.ipva_debt);
    document.getElementById('total-debt').textContent = formatMoney(total);
    document.getElementById('vehicles-with-debt').textContent = debts.length;

    // Fetch and update Impostômetro
    const impostometro = await post('getImpostometro', {});
    const impostometroTotal = document.getElementById('impostometro-total');
    if (impostometroTotal) {
        impostometroTotal.textContent = formatMoney(impostometro || 0);
    }

    if (!debts || debts.length === 0) {
        list.innerHTML = '<div class="empty-state"><p>Nenhuma pendência encontrada.</p></div>';
        return;
    }

    list.innerHTML = debts.map(v => `
        <div class="vehicle-card">
            <div class="vehicle-header">
                <span class="plate-label">${v.plate}</span>
                <span class="model-label">${v.owner_name}</span>
            </div>
            <div class="vehicle-body">
                <p>Débito acumulado: <span class="debt">${formatMoney(v.ipva_debt)}</span></p>
                <button class="btn" onclick="openIPVAReceipt('${v.plate}', ${v.ipva_debt}, '${v.owner_name}')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/>
                    </svg>
                    Gerar Recibo
                </button>
            </div>
        </div>
    `).join('');
}

window.openIPVAReceipt = function(plate, amount, owner) {
    const modal = document.getElementById('ipva-receipt-container');
    const tax = Math.floor(amount * 0.18);
    const total = amount + tax;
    
    document.getElementById('receipt-id').textContent = `ZN#${Math.floor(1000 + Math.random() * 9000)}`;
    document.getElementById('receipt-date').textContent = new Date().toLocaleDateString('pt-BR') + " " + new Date().toLocaleTimeString('pt-BR', {hour: '2-digit', minute:'2-digit'});
    document.getElementById('receipt-user').textContent = owner.toUpperCase();
    document.getElementById('receipt-plate').textContent = plate.toUpperCase();
    document.getElementById('receipt-summary').textContent = formatMoney(amount);
    document.getElementById('receipt-tax').textContent = formatMoney(tax);
    document.getElementById('receipt-total').textContent = formatMoney(total);
    
    document.getElementById('confirm-payment-btn').onclick = () => confirmIPVAPayment(plate);
    
    modal.classList.add('active');
};

window.closeReceipt = function() {
    document.getElementById('ipva-receipt-container').classList.remove('active');
};

async function confirmIPVAPayment(plate) {
    const result = await post('payIPVA', { plate });
    if (result.success) {
        showNotification('IPVA pago com sucesso!', 'success');
        closeReceipt();
        loadIPVADebts();
    } else {
        showNotification(result.message || 'Erro no pagamento', 'error');
    }
}

async function loadDocumentsIssuance() {
    const list = document.getElementById('documents-issuance-list');
    list.innerHTML = '<div class="loading">Carregando...</div>';
    
    const docs = [
        { id: 'id', label: 'Identidade (RG)', description: 'Emissão de cédula de identidade civil oficial.', price: 1000, icon: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2' },
        { id: 'drive', label: 'Habilitação (CNH)', description: 'Carteira Nacional de Habilitação (Necessário teste).', price: 1000, icon: 'M18 11V6a2 2 0 0 0-2-2v0a2 2 0 0 0-2 2v5' },
        { id: 'passport', label: 'Passaporte', description: 'Documento oficial para viagens internacionais.', price: 10000, icon: 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z' }
    ];

    list.innerHTML = docs.map(doc => `
        <div class="doc-issue-card">
            <div class="icon-container">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="${doc.icon}"/>
                </svg>
            </div>
            <div class="doc-issue-info">
                <h3>${doc.label}</h3>
                <p>${doc.description}</p>
            </div>
            <div class="card-footer">
                <span class="price">$${doc.price}</span>
                <button class="btn btn-primary" onclick="requestDocument('${doc.id}')">Solicitar</button>
            </div>
        </div>
    `).join('');
}

async function requestDocument(type) {
    if (type === 'drive' && !playerData.cnhValidated) {
        showNotification('Você precisa passar no teste de CNH primeiro!', 'error');
        navigateToPage('cnh');
        return;
    }

    const result = await post('issueDocument', { type: type });
    if (result.success) {
        showNotification('Documento emitido com sucesso!', 'success');
        post('getPlayerData', {}).then(data => playerData = data);
    } else {
        showNotification(result.message || 'Erro ao emitir documento', 'error');
    }
}

async function consultVehicle() {
    const query = document.getElementById('consult-plate').value;
    if (!query) return;

    const btn = document.getElementById('consult-btn');
    btn.innerText = 'BUSCANDO...';
    btn.disabled = true;

    try {
        const result = await post('consultVehicle', { plate: query });
        btn.innerText = 'PESQUISAR';
        btn.disabled = false;

        const emptyState = document.querySelector('.dmv-empty-state');
        const editor = document.getElementById('dmv-editor');
        const saveBtn = document.getElementById('save-dmv-btn');

        if (result.success) {
            if (emptyState) emptyState.classList.add('hidden');
            editor.classList.remove('hidden');
            if (saveBtn) saveBtn.style.display = 'none'; // Sempre escondido na pesquisa pública

            // Popular campos do editor (apenas leitura na aba de pesquisa)
            document.getElementById('dmv-plate').value = result.plate;
            document.getElementById('dmv-owner').value = result.owner_name || result.owner || 'N/A';
            document.getElementById('dmv-model').value = result.description;
            document.getElementById('dmv-color').value = result.color || 'N/A';
            
            const imgInput = document.getElementById('dmv-img-url');
            imgInput.value = result.image_url || '';
            imgInput.readOnly = true;
            
            const obsInput = document.getElementById('dmv-observations');
            obsInput.value = result.observations || '';
            obsInput.readOnly = true;
            
            const vehicleImg = document.getElementById('dmv-vehicle-img');
            vehicleImg.src = result.image_url || 'images/not-found.webp';
            
            // Preview da imagem ao digitar a URL
            document.getElementById('dmv-img-url').oninput = (e) => {
                vehicleImg.src = e.target.value || 'images/not-found.webp';
            };
        } else {
            if (emptyState) {
                emptyState.classList.remove('hidden');
                emptyState.innerHTML = `<p style="color: var(--danger)">${result.message}</p>`;
            }
            editor.classList.add('hidden');
            saveBtn.style.display = 'none';
        }
    } catch (error) {
        btn.innerText = 'PESQUISAR';
        btn.disabled = false;
        console.error('Error in consultVehicle:', error);
    }
}

async function saveVehicleManagement() {
    const data = {
        plate: document.getElementById('dmv-plate').value,
        image_url: document.getElementById('dmv-img-url').value,
        observations: document.getElementById('dmv-observations').value
    };

    const saveBtn = document.getElementById('save-dmv-btn');
    const originalText = saveBtn.innerText;
    saveBtn.innerText = 'SALVANDO...';
    saveBtn.disabled = true;

    const result = await post('saveVehicleManagement', data);
    
    saveBtn.innerText = originalText;
    saveBtn.disabled = false;

    if (result.success) {
        showNotification('Dados salvos com sucesso!', 'success');
    } else {
        showNotification(result.message || 'Erro ao salvar dados.', 'error');
    }
}

// Editar Veículo do Próprio Usuário (Meus Veículos)
window.openMyVehicleEdit = function(plate, currentImg, currentObs) {
    // Esconde a lista e form de registro
    document.getElementById('vehicles-list').classList.add('hidden');
    const regContainer = document.getElementById('registration-form-container');
    if (regContainer) regContainer.classList.add('hidden');
    
    // Mostra o formulário de edição
    const editContainer = document.getElementById('edit-form-container');
    editContainer.classList.remove('hidden');
    
    // Preenche os dados
    document.getElementById('edit-plate').value = plate;
    document.getElementById('edit-img-url').value = currentImg !== 'null' ? currentImg : '';
    document.getElementById('edit-observations').value = currentObs !== 'null' ? currentObs : '';
};

window.cancelVehicleEdit = function() {
    document.getElementById('edit-form-container').classList.add('hidden');
    document.getElementById('vehicles-list').classList.remove('hidden');
};

window.submitVehicleEdit = async function() {
    const data = {
        plate: document.getElementById('edit-plate').value,
        image_url: document.getElementById('edit-img-url').value,
        observations: document.getElementById('edit-observations').value
    };

    const result = await post('saveVehicleManagement', data);
    
    if (result.success) {
        showNotification('Dados do veículo atualizados com sucesso!', 'success');
        cancelVehicleEdit();
        loadMyVehicles(); // Recarrega a lista
    } else {
        showNotification(result.message || 'Erro ao atualizar dados.', 'error');
    }
};

// Helpers

function resetConsultationPage() {
    const input = document.getElementById('consult-plate');
    if (input) input.value = '';
    
    const emptyState = document.querySelector('.dmv-empty-state');
    const editor = document.getElementById('dmv-editor');
    
    if (emptyState) {
        emptyState.classList.remove('hidden');
        emptyState.innerHTML = '<p>Pesquise um veículo para visualizar ou editar as informações.</p>';
    }
    if (editor) editor.classList.add('hidden');
    
    const saveBtn = document.getElementById('save-dmv-btn');
    if (saveBtn) saveBtn.style.display = 'none';
}

async function post(event, data) {
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 seconds timeout
        
        const resp = await fetch(`https://${GetParentResourceName()}/${event}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data),
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (!resp.ok) throw new Error(`HTTP error! status: ${resp.status}`);
        return await resp.json();
    } catch (error) {
        console.error(`[ZN-DOCUMENTS] Fetch error on ${event}:`, error);
        let errorMsg = "Erro de conexão com o servidor.";
        if (error.name === 'AbortError') {
            errorMsg = "Tempo de resposta excedido (Timeout).";
        }
        return { success: false, message: errorMsg };
    }
}

function formatMoney(n) {
    return '$' + n.toLocaleString('pt-BR');
}

function showNotification(msg, type) {
    if (type === 'error') console.error(`[ZN-DOCUMENTS]: ${msg}`);
    else console.log(`[ZN-DOCUMENTS]: ${msg}`);
    
    // Enviar para o Lua para mostrar notificação real in-game
    fetch(`https://${GetParentResourceName()}/notify`, {
        method: 'POST',
        body: JSON.stringify({ message: msg, type: type })
    });
}

function copyPlate(plate) {
    const textarea = document.createElement('textarea');
    textarea.value = plate;
    // Evitar que o scroll desça ao criar o elemento
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    try {
        const successful = document.execCommand('copy');
        if (successful) {
            showNotification(`Placa ${plate} copiada!`, 'success');
        } else {
            showNotification('Erro ao copiar placa', 'error');
        }
    } catch (err) {
        showNotification('Erro ao copiar placa', 'error');
    }
    document.body.removeChild(textarea);
}

window.copyPlate = copyPlate;
window.selectOption = selectOption;
window.closeUI = closeUI;
window.closeDocumentViewer = closeDocumentViewer;
window.requestDocument = requestDocument;
window.navigateToPage = navigateToPage;
