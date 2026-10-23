document.addEventListener('DOMContentLoaded', () => {
    const statusText = document.getElementById('status-text');
    const metricEnv = document.getElementById('metric-env');
    const metricOs = document.getElementById('metric-os');
    const metricHost = document.getElementById('metric-host');
    const metricRam = document.getElementById('metric-ram');
    const ramProgress = document.getElementById('ram-progress');
    const ramSub = document.getElementById('ram-sub');
    const metricUptime = document.getElementById('metric-uptime');
    const metricLatency = document.getElementById('metric-latency');
    const currentEndpoint = document.getElementById('current-endpoint');
    const httpStatus = document.getElementById('http-status');
    const jsonOutput = document.getElementById('json-output');
    const btnRefresh = document.getElementById('btn-refresh-all');
    const apiButtons = document.querySelectorAll('.api-btn');
    const nameInput = document.getElementById('name-input');
    const btnCustomGreet = document.getElementById('btn-custom-greet');
    const greetingAlert = document.getElementById('greeting-alert');
    const greetingMessage = document.getElementById('greeting-message');

    async function fetchEndpoint(url, method = 'GET') {
        currentEndpoint.textContent = `${method} ${url}`;
        jsonOutput.textContent = 'Executing request...';
        httpStatus.textContent = '...';
        httpStatus.style.color = '#94a3b8';

        try {
            const start = performance.now();
            const response = await fetch(url, { method });
            const duration = Math.round(performance.now() - start);
            const data = await response.json();

            httpStatus.textContent = `${response.status} ${response.statusText} (${duration}ms)`;
            httpStatus.style.color = response.ok ? '#10b981' : '#ef4444';
            jsonOutput.textContent = JSON.stringify(data, null, 2);
            if (metricLatency) metricLatency.textContent = `Ping: ${duration}ms`;
            return data;
        } catch (err) {
            httpStatus.textContent = 'Request Failed';
            httpStatus.style.color = '#ef4444';
            jsonOutput.textContent = JSON.stringify({
                error: err.message,
                hint: 'Ensure application is running on port 80 and security group allows inbound traffic.'
            }, null, 2);
            if (metricLatency) metricLatency.textContent = 'Ping: Error';
            return null;
        }
    }

    async function loadStatus() {
        const data = await fetchEndpoint('/api/status');
        if (data && data.status !== 'error') {
            statusText.textContent = 'Server Online (v2.0)';
            if (data.environment && metricEnv) metricEnv.textContent = data.environment;
            if (data.hostname) metricHost.textContent = data.hostname;
            if (data.os) metricOs.textContent = `${data.os} (Java ${data.javaVersion || ''})`;
            if (data.uptime) metricUptime.textContent = data.uptime;

            if (data.jvmMemory) {
                const used = data.jvmMemory.usedMb || 0;
                const total = data.jvmMemory.totalMb || 0;
                const max = data.jvmMemory.maxMb || total || 1;
                metricRam.textContent = `${used} / ${total} MB`;
                const percentage = Math.min(100, Math.round((used / max) * 100));
                ramProgress.style.width = `${percentage}%`;
                ramSub.textContent = `Max Allocated: ${max} MB (${percentage}%)`;
            }
        }
    }

    // Custom Greeting Click
    if (btnCustomGreet) {
        btnCustomGreet.addEventListener('click', async () => {
            const name = encodeURIComponent(nameInput.value.trim() || 'DevOps Engineer');
            const data = await fetchEndpoint(`/api/greet?name=${name}`);
            if (data && data.message) {
                greetingMessage.textContent = data.message;
                greetingAlert.classList.remove('hidden');
            }
        });
    }

    // Bind API button clicks
    apiButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            apiButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const url = btn.getAttribute('data-url');
            const method = btn.getAttribute('data-method') || 'GET';
            fetchEndpoint(url, method);
        });
    });

    btnRefresh.addEventListener('click', () => {
        loadStatus();
    });

    // Initial load
    loadStatus();

    // Refresh every 30 seconds
    setInterval(loadStatus, 30000);
});
