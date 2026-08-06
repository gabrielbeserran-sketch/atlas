const STORAGE = {
  token: 'atlas_admin_token',
  baseUrl: 'atlas_admin_base_url',
};

const S = {
  token: localStorage.getItem(STORAGE.token) || '',
  view: 'overview',
  session: null,
  loading: false,
};

const $ = (id) => document.getElementById(id);

function base() {
  const value = $('base').value.trim().replace(/\/+$/, '');
  localStorage.setItem(STORAGE.baseUrl, value);
  return value;
}

function setStatus(message, kind = '') {
  const element = $('status-message');
  element.textContent = message || '';
  element.className = `status-message ${kind}`.trim();
}

function setSessionText() {
  const session = $('session');

  if (!S.token || !S.session) {
    session.textContent = 'Sem sessão.';
    $('logout').hidden = true;
    return;
  }

  session.textContent =
    `${S.session.user_name} • ${S.session.role} • ${S.session.company_id}`;
  $('logout').hidden = false;
}

function clearSession(message = 'Sessão encerrada.') {
  S.token = '';
  S.session = null;
  localStorage.removeItem(STORAGE.token);
  setSessionText();
  if (message) setStatus(message, 'warning');
}

async function parseResponse(response) {
  const text = await response.text();
  if (!text) return {};

  try {
    return JSON.parse(text);
  } catch (_) {
    return { detail: text };
  }
}

async function req(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  if (S.token) headers.Authorization = `Bearer ${S.token}`;

  let response;
  try {
    response = await fetch(base() + path, { ...options, headers });
  } catch (_) {
    throw new Error('Não foi possível conectar à API Atlas.');
  }

  const body = await parseResponse(response);

  if (response.status === 401) {
    clearSession('Sua sessão expirou. Entre novamente.');
    throw new Error(body.detail || 'Sessão expirada.');
  }

  if (response.status === 403) {
    throw new Error(body.detail || 'Você não possui permissão para esta operação.');
  }

  if (!response.ok) {
    throw new Error(body.detail || body.error || `HTTP ${response.status}`);
  }

  return body;
}

function esc(value) {
  return String(value ?? '').replace(
    /[&<>"']/g,
    (char) => ({
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;',
    })[char],
  );
}

function table(rows, columns, options = {}) {
  if (!rows.length) return '<p class="empty-state">Nenhum registro.</p>';

  const actions = options.actions;
  return `
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            ${columns.map((column) => `<th>${esc(column)}</th>`).join('')}
            ${actions ? '<th>Ações</th>' : ''}
          </tr>
        </thead>
        <tbody>
          ${rows.map((row) => `
            <tr>
              ${columns.map((column) => `<td>${esc(row[column])}</td>`).join('')}
              ${actions ? `<td>${actions(row)}</td>` : ''}
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>
  `;
}

async function health() {
  try {
    const result = await req('/health');
    $('health').textContent = `${result.status} • ${result.database}`;
    $('health').classList.remove('offline');
    return result;
  } catch (_) {
    $('health').textContent = 'API indisponível';
    $('health').classList.add('offline');
    return null;
  }
}

async function restoreSession() {
  if (!S.token) {
    setSessionText();
    return false;
  }

  try {
    S.session = await req('/auth/me');
    setSessionText();
    return true;
  } catch (_) {
    clearSession('');
    return false;
  }
}

async function login() {
  setStatus('');
  const email = $('email').value.trim();
  const password = $('password').value;

  if (!email || !password) {
    setStatus('Informe e-mail e senha.', 'warning');
    return;
  }

  $('login').disabled = true;
  try {
    const response = await req('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });

    S.token = response.access_token;
    S.session = response;
    localStorage.setItem(STORAGE.token, S.token);
    $('password').value = '';
    setSessionText();
    setStatus('Sessão iniciada com sucesso.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    $('login').disabled = false;
  }
}

function logout() {
  clearSession('Sessão encerrada.');
  render();
}

async function switchCompany(companyId) {
  if (!companyId) return;

  try {
    const response = await req('/auth/switch-company', {
      method: 'POST',
      body: JSON.stringify({ company_id: companyId }),
    });

    S.token = response.access_token;
    S.session = response;
    localStorage.setItem(STORAGE.token, S.token);
    setSessionText();
    setStatus('Empresa ativa alterada com sucesso.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  }
}

async function createCompany(event) {
  event.preventDefault();
  setStatus('');

  const name = $('company-name').value.trim();
  const documentValue = $('company-document').value.trim();
  const plan = $('company-plan').value.trim();

  if (!name) {
    setStatus('Informe o nome da empresa.', 'warning');
    return;
  }

  $('company-save').disabled = true;
  try {
    await req('/companies', {
      method: 'POST',
      body: JSON.stringify({
        name,
        document: documentValue,
        subscription_plan: plan || 'enterprise',
      }),
    });

    $('company-name').value = '';
    $('company-document').value = '';
    $('company-plan').value = 'enterprise';
    setStatus('Empresa criada e vinculada ao administrador atual.', 'success');
    S.session = await req('/auth/me');
    setSessionText();
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    $('company-save').disabled = false;
  }
}

async function updateCompany(event) {
  event.preventDefault();
  setStatus('');

  if (!S.session?.company_id) return;

  const name = $('current-company-name').value.trim();
  const documentValue = $('current-company-document').value.trim();
  const plan = $('current-company-plan').value.trim();

  if (!name || !plan) {
    setStatus('Nome e plano são obrigatórios.', 'warning');
    return;
  }

  $('current-company-save').disabled = true;
  try {
    await req(`/companies/${S.session.company_id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        name,
        document: documentValue,
        subscription_plan: plan,
      }),
    });

    S.session = await req('/auth/me');
    setSessionText();
    setStatus('Dados da empresa atualizados.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    $('current-company-save').disabled = false;
  }
}


function roleLabel(role) {
  const labels = {
    companyAdministrator: 'Administrador da empresa',
    manager: 'Gerente',
    consultant: 'Consultor',
    veterinarian: 'Veterinário',
    technician: 'Técnico',
    financial: 'Financeiro',
    operator: 'Operador',
    viewer: 'Leitura',
    auditor: 'Auditor',
  };
  return labels[role] || role;
}

function permissionLabel(permission) {
  const labels = {
    'companies.read': 'Visualizar empresas',
    'companies.create': 'Criar empresas',
    'companies.manage': 'Editar empresa',
    'members.read': 'Visualizar usuários',
    'members.manage': 'Gerenciar usuários e permissões',
    'farms.read': 'Visualizar fazendas',
    'farms.create': 'Cadastrar fazendas',
    'farms.update': 'Editar fazendas',
    'sync.read': 'Ler sincronização',
    'sync.manage': 'Enviar alterações sincronizadas',
    'audit.read': 'Visualizar auditoria',
    'backup.read': 'Visualizar backups',
    'backup.run': 'Executar backup',
    'system.read': 'Visualizar sistema',
    'reports.read': 'Visualizar relatórios',
  };
  return labels[permission] || permission;
}

function memberCreateForm(catalog, farms) {
  return `
    <div class="card">
      <h2>Novo usuário</h2>
      <p class="muted">Crie um usuário ou vincule um e-mail já existente à empresa ativa.</p>
      <form id="member-create-form" class="member-form">
        <label>Nome<input id="member-name" placeholder="Nome completo" autocomplete="off"></label>
        <label>E-mail<input id="member-email" type="email" placeholder="usuario@empresa.com" autocomplete="off"></label>
        <label>Senha inicial<input id="member-password" type="password" placeholder="Mínimo de 8 caracteres"></label>
        <label>Perfil
          <select id="member-role">
            ${catalog.roles.map((role) => `<option value="${esc(role)}">${esc(roleLabel(role))}</option>`).join('')}
          </select>
        </label>
        <label class="full-span">Escopo de fazendas
          <select id="member-farms" multiple size="${Math.min(Math.max(farms.length, 3), 7)}">
            ${farms.map((farm) => `<option value="${esc(farm.id)}">${esc(farm.name)} — ${esc(farm.city)}/${esc(farm.state)}</option>`).join('')}
          </select>
          <small>Nenhuma seleção = acesso a todas as fazendas permitido pelo perfil.</small>
        </label>
        <button id="member-create" type="submit">Criar / vincular usuário</button>
      </form>
    </div>
  `;
}

function memberEditor(member, catalog, farms) {
  const overrides = member.permission_overrides || {};
  return `
    <div class="card member-editor-card">
      <div class="card-title-row">
        <div>
          <h2>Editar acesso — ${esc(member.name)}</h2>
          <p class="muted">${esc(member.email)}${member.is_self ? ' • sua própria conta' : ''}</p>
        </div>
        <button class="secondary-button" id="member-editor-close" type="button">Fechar</button>
      </div>

      <form id="member-edit-form" class="member-form">
        <label>Perfil
          <select id="edit-member-role" ${member.is_self ? 'disabled' : ''}>
            ${catalog.roles.map((role) => `<option value="${esc(role)}" ${role === member.role ? 'selected' : ''}>${esc(roleLabel(role))}</option>`).join('')}
          </select>
        </label>
        <label class="toggle-label">Vínculo ativo
          <input id="edit-member-active" type="checkbox" ${member.active ? 'checked' : ''} ${member.is_self ? 'disabled' : ''}>
        </label>
        <label class="full-span">Fazendas autorizadas
          <select id="edit-member-farms" multiple size="${Math.min(Math.max(farms.length, 3), 7)}">
            ${farms.map((farm) => `<option value="${esc(farm.id)}" ${(member.farm_ids || []).includes(farm.id) ? 'selected' : ''}>${esc(farm.name)} — ${esc(farm.city)}/${esc(farm.state)}</option>`).join('')}
          </select>
          <small>Nenhuma seleção = todas as fazendas permitidas pelo perfil.</small>
        </label>

        <div class="full-span permission-panel">
          <h3>Overrides de permissões</h3>
          <p class="muted">Padrão usa as permissões do perfil. Permitir ou Negar substitui somente aquela permissão.</p>
          <div class="permission-grid">
            ${catalog.permissions.map((permission) => `
              <label class="permission-row">
                <span>${esc(permissionLabel(permission))}<small>${esc(permission)}</small></span>
                <select data-permission="${esc(permission)}">
                  <option value="" ${!overrides[permission] ? 'selected' : ''}>Padrão do perfil</option>
                  <option value="allow" ${overrides[permission] === 'allow' ? 'selected' : ''}>Permitir</option>
                  <option value="deny" ${overrides[permission] === 'deny' ? 'selected' : ''}>Negar</option>
                </select>
              </label>
            `).join('')}
          </div>
        </div>

        <div class="full-span effective-box">
          <strong>Permissões efetivas atuais</strong>
          <p>${(member.effective_permissions || []).map((permission) => `<span class="permission-chip">${esc(permission)}</span>`).join(' ') || 'Nenhuma.'}</p>
        </div>

        <button id="member-save" type="submit">Salvar acesso</button>
      </form>

      ${member.is_self ? '' : `
        <form id="member-password-form" class="password-reset-form">
          <label>Nova senha<input id="member-new-password" type="password" placeholder="Mínimo de 8 caracteres"></label>
          <button id="member-password-save" type="submit">Redefinir senha</button>
        </form>
      `}
    </div>
  `;
}

function selectedValues(select) {
  return Array.from(select.selectedOptions).map((option) => option.value);
}

async function createMember(event) {
  event.preventDefault();
  setStatus('');

  const name = $('member-name').value.trim();
  const email = $('member-email').value.trim();
  const password = $('member-password').value;
  const role = $('member-role').value;
  const farmIds = selectedValues($('member-farms'));

  if (!name || !email) {
    setStatus('Informe nome e e-mail.', 'warning');
    return;
  }

  $('member-create').disabled = true;
  try {
    await req('/members', {
      method: 'POST',
      body: JSON.stringify({
        name,
        email,
        password: password || null,
        role,
        farm_ids: farmIds,
        permission_overrides: {},
      }),
    });
    setStatus('Usuário vinculado à empresa com sucesso.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    if ($('member-create')) $('member-create').disabled = false;
  }
}

async function openMemberEditor(membershipId) {
  const [members, catalog, farms] = await Promise.all([
    req('/members'),
    req('/members/catalog'),
    req('/farms'),
  ]);
  const member = members.find((item) => item.membership_id === membershipId);
  if (!member) {
    setStatus('Usuário não encontrado.', 'error');
    return;
  }

  const host = $('member-editor-host');
  host.innerHTML = memberEditor(member, catalog, farms);
  host.scrollIntoView({ behavior: 'smooth', block: 'start' });

  $('member-editor-close').addEventListener('click', () => { host.innerHTML = ''; });
  $('member-edit-form').addEventListener('submit', (event) => updateMember(event, member));
  if ($('member-password-form')) {
    $('member-password-form').addEventListener('submit', (event) => resetMemberPassword(event, member));
  }
}

async function updateMember(event, member) {
  event.preventDefault();
  setStatus('');

  const role = member.is_self ? member.role : $('edit-member-role').value;
  const active = member.is_self ? member.active : $('edit-member-active').checked;
  const farmIds = selectedValues($('edit-member-farms'));
  const overrides = {};
  document.querySelectorAll('[data-permission]').forEach((select) => {
    if (select.value) overrides[select.dataset.permission] = select.value;
  });

  $('member-save').disabled = true;
  try {
    await req(`/members/${member.membership_id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        role,
        active,
        farm_ids: farmIds,
        permission_overrides: overrides,
      }),
    });
    setStatus('Perfil e permissões atualizados.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    if ($('member-save')) $('member-save').disabled = false;
  }
}

async function resetMemberPassword(event, member) {
  event.preventDefault();
  const password = $('member-new-password').value;
  if (password.length < 8) {
    setStatus('A nova senha deve possuir ao menos 8 caracteres.', 'warning');
    return;
  }

  $('member-password-save').disabled = true;
  try {
    await req(`/members/${member.membership_id}/reset-password`, {
      method: 'POST',
      body: JSON.stringify({ password }),
    });
    $('member-new-password').value = '';
    setStatus('Senha redefinida com sucesso.', 'success');
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    $('member-password-save').disabled = false;
  }
}

async function createFarm(event) {
  event.preventDefault();
  setStatus('');

  const name = $('farm-name').value.trim();
  const city = $('farm-city').value.trim();
  const state = $('farm-state').value.trim().toUpperCase();

  if (!name || !city || !state) {
    setStatus('Preencha nome, cidade e estado.', 'warning');
    return;
  }

  if (state.length > 2) {
    setStatus('Use a sigla do estado com 2 letras, por exemplo DF.', 'warning');
    return;
  }

  $('farm-save').disabled = true;
  try {
    await req('/farms', {
      method: 'POST',
      body: JSON.stringify({ name, city, state }),
    });

    $('farm-name').value = '';
    $('farm-city').value = '';
    $('farm-state').value = '';
    setStatus('Fazenda cadastrada com sucesso.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    $('farm-save').disabled = false;
  }
}

async function backup() {
  const button = $('backup-run');
  if (button) button.disabled = true;

  try {
    await req('/backups/run', { method: 'POST' });
    setStatus('Backup executado com sucesso.', 'success');
    await render();
  } catch (error) {
    setStatus(error.message, 'error');
  } finally {
    if (button) button.disabled = false;
  }
}

function renderFarmForm() {
  return `
    <div class="card">
      <h2>Nova fazenda</h2>
      <p class="muted">O cadastro será vinculado automaticamente à empresa e ao tenant da sessão atual.</p>
      <form id="farm-form" class="farm-form">
        <label>Nome<input id="farm-name" autocomplete="off" placeholder="Ex.: Fazenda Primavera"></label>
        <label>Cidade<input id="farm-city" autocomplete="off" placeholder="Ex.: Brasília"></label>
        <label>Estado<input id="farm-state" maxlength="2" autocomplete="off" placeholder="DF"></label>
        <button id="farm-save" type="submit">Cadastrar fazenda</button>
      </form>
    </div>
  `;
}

function companyForms(activeCompany) {
  return `
    <div class="company-grid">
      <div class="card">
        <h2>Empresa atual</h2>
        <p class="muted">Edite os dados cadastrais da empresa ativa da sessão.</p>
        <form id="current-company-form" class="stack-form">
          <label>Nome<input id="current-company-name" value="${esc(activeCompany?.name || '')}"></label>
          <label>Documento<input id="current-company-document" value="${esc(activeCompany?.document || '')}" placeholder="CNPJ ou identificador"></label>
          <label>Plano<input id="current-company-plan" value="${esc(activeCompany?.subscription_plan || 'enterprise')}"></label>
          <div class="read-only-grid">
            <div><span>Status</span><strong>${esc(activeCompany?.status || '')}</strong></div>
            <div><span>Tenant</span><strong>${esc(activeCompany?.tenant_id || '')}</strong></div>
          </div>
          <button id="current-company-save" type="submit">Salvar empresa atual</button>
        </form>
      </div>

      <div class="card">
        <h2>Nova empresa</h2>
        <p class="muted">Cria um novo tenant e vincula o administrador atual como companyAdministrator.</p>
        <form id="company-form" class="stack-form">
          <label>Nome<input id="company-name" placeholder="Ex.: Grupo Pecuário Atlas"></label>
          <label>Documento<input id="company-document" placeholder="CNPJ ou identificador"></label>
          <label>Plano<input id="company-plan" value="enterprise"></label>
          <button id="company-save" type="submit">Criar empresa</button>
        </form>
      </div>
    </div>
  `;
}

async function render() {
  if (S.loading) return;
  S.loading = true;

  const view = $('view');
  view.innerHTML = '<div class="card"><p>Carregando...</p></div>';

  await health();
  if (S.token && !S.session) await restoreSession();

  if (!S.token && S.view !== 'system') {
    view.innerHTML = `
      <div class="card">
        <h2>Autenticação necessária</h2>
        <p class="muted">Entre com uma conta autorizada para acessar os dados administrativos.</p>
      </div>
    `;
    S.loading = false;
    return;
  }

  try {
    if (S.view === 'overview') {
      const [farms, audit, backups] = await Promise.all([
        req('/farms'),
        req('/audit?limit=100'),
        req('/backups'),
      ]);

      view.innerHTML = `
        <div class="grid">
          <div class="metric">Fazendas<strong>${farms.length}</strong></div>
          <div class="metric">Auditoria<strong>${audit.length}</strong></div>
          <div class="metric">Backups<strong>${backups.length}</strong></div>
          <div class="metric">Sessão<strong>JWT</strong></div>
        </div>
        <div class="card">
          <h2>Últimos eventos</h2>
          ${table(audit.slice(0, 10), ['occurred_at', 'module', 'action', 'description', 'result'])}
        </div>
      `;
    } else if (S.view === 'companies') {
      const companies = await req('/companies');
      const activeCompany = companies.find((item) => item.active);

      view.innerHTML = `
        ${companyForms(activeCompany)}
        <div class="card">
          <h2>Empresas autorizadas</h2>
          <p class="muted">Somente empresas vinculadas ao usuário autenticado são exibidas.</p>
          ${table(
            companies,
            ['name', 'document', 'status', 'subscription_plan', 'role', 'farm_count', 'member_count'],
            {
              actions: (company) => company.active
                ? '<span class="badge">Ativa</span>'
                : `<button class="small-button" data-company="${esc(company.id)}">Usar empresa</button>`,
            },
          )}
        </div>
      `;

      $('company-form').addEventListener('submit', createCompany);
      if ($('current-company-form')) $('current-company-form').addEventListener('submit', updateCompany);
      document.querySelectorAll('[data-company]').forEach((button) => {
        button.addEventListener('click', () => switchCompany(button.dataset.company));
      });
    } else if (S.view === 'members') {
      const [members, catalog, farms] = await Promise.all([
        req('/members'),
        req('/members/catalog'),
        req('/farms'),
      ]);

      view.innerHTML = `
        ${memberCreateForm(catalog, farms)}
        <div id="member-editor-host"></div>
        <div class="card">
          <h2>Usuários autorizados</h2>
          <p class="muted">Os usuários abaixo pertencem somente à empresa ativa. Alterar a empresa ativa troca automaticamente o escopo desta lista.</p>
          ${table(
            members.map((member) => ({
              ...member,
              role_label: roleLabel(member.role),
              status_label: member.active ? 'Ativo' : 'Inativo',
              farm_scope: member.farm_ids?.length ? `${member.farm_ids.length} selecionada(s)` : 'Todas',
            })),
            ['name', 'email', 'role_label', 'status_label', 'farm_scope'],
            {
              actions: (member) => `<button class="small-button" data-member-edit="${esc(member.membership_id)}">Editar</button>`,
            },
          )}
        </div>
      `;

      $('member-create-form').addEventListener('submit', createMember);
      document.querySelectorAll('[data-member-edit]').forEach((button) => {
        button.addEventListener('click', () => openMemberEditor(button.dataset.memberEdit));
      });
    } else if (S.view === 'farms') {
      const farms = await req('/farms');
      view.innerHTML = `
        ${renderFarmForm()}
        <div class="card">
          <h2>Fazendas</h2>
          <p class="muted">${farms.length} fazenda(s) disponível(is) no escopo atual.</p>
          ${table(farms, ['id', 'name', 'city', 'state', 'active'])}
        </div>
      `;
      $('farm-form').addEventListener('submit', createFarm);
    } else if (S.view === 'audit') {
      const audit = await req('/audit?limit=500');
      view.innerHTML = `
        <div class="card">
          <h2>Auditoria</h2>
          ${table(audit, ['occurred_at', 'user_id', 'module', 'action', 'entity_type', 'description', 'result'])}
        </div>
      `;
    } else if (S.view === 'backups') {
      const backups = await req('/backups');
      view.innerHTML = `
        <div class="card">
          <div class="card-title-row">
            <div><h2>Backups</h2><p class="muted">Backups persistidos no volume Docker do Atlas Enterprise.</p></div>
            <button id="backup-run">Executar backup</button>
          </div>
          ${table(backups, ['filename', 'created_at', 'size_bytes', 'engine'])}
        </div>
      `;
      $('backup-run').addEventListener('click', backup);
    } else {
      const healthResult = await health();
      let statusResult = {};
      if (S.token) {
        try {
          statusResult = await req('/system/status');
        } catch (error) {
          statusResult = { error: error.message };
        }
      }
      view.innerHTML = `
        <div class="card">
          <h2>Sistema</h2>
          <pre>${esc(JSON.stringify({ health: healthResult, status: statusResult }, null, 2))}</pre>
        </div>
      `;
    }
  } catch (error) {
    view.innerHTML = `<div class="card"><h2>Não foi possível carregar esta área</h2><p>${esc(error.message)}</p></div>`;
  } finally {
    S.loading = false;
  }
}

function initNavigation() {
  document.querySelectorAll('aside button[data-v]').forEach((button) => {
    button.addEventListener('click', () => {
      S.view = button.dataset.v;
      document.querySelectorAll('aside button[data-v]').forEach((item) => {
        item.classList.toggle('active', item === button);
      });
      render();
    });
  });
}

async function init() {
  const storedBase = localStorage.getItem(STORAGE.baseUrl);
  if (storedBase) $('base').value = storedBase;

  initNavigation();
  $('login').addEventListener('click', login);
  $('logout').addEventListener('click', logout);
  $('refresh').addEventListener('click', render);
  $('password').addEventListener('keydown', (event) => {
    if (event.key === 'Enter') login();
  });

  await health();
  await restoreSession();
  await render();
}

init();
