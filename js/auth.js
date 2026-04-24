async function doLogin() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('senha').value;

    const response = await fetch('http://localhost:8080/api/auth/login', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ email, password })
    });

    if (response.ok) {
        window.location.href = 'perfil.html';
    } else {
        alert("Falha na autenticação");
    }
}

async function doRegister() {
    const dados = {
        nome: document.getElementById('nome').value,
        email: document.getElementById('email').value,
        curso: document.getElementById('curso').value,
        senha: document.getElementById('senha').value
    };

    const response = await fetch('http://localhost:8080/api/auth/cadastro', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(dados)
    });

    if (response.ok) {
        window.location.href = 'login.html';
    }
}