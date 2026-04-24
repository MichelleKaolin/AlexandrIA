async function processarDocumento(file) {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch('http://localhost:8000/ia/resumir', {
        method: 'POST',
        body: formData
    });

    const data = await response.json();
    localStorage.setItem('ultimoResumo', data.resumo);
    window.location.href = 'resumo.html';
}