        let qrStream = null;
        let scanningQr = false;
        let handlingQr = false;

        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('start-scan').addEventListener('click', startQrScan);
            document.getElementById('stop-scan').addEventListener('click', stopQrScan);
        });

        async function startQrScan() {
            if (scanningQr || handlingQr) return;
            const status = document.getElementById('qr-scan-status');
            status.textContent = t('scanStarting');

            if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
                status.textContent = t('cameraUnsupported');
                return;
            }

            try {
                qrStream = await navigator.mediaDevices.getUserMedia({
                    video: {
                        facingMode: { ideal: 'environment' },
                        width: { ideal: 1280 },
                        height: { ideal: 720 }
                    },
                    audio: false
                });
                const video = document.getElementById('qr-video');
                video.srcObject = qrStream;
                await video.play();
                scanningQr = true;
                document.getElementById('qr-camera').classList.remove('hidden');
                document.getElementById('stop-scan').classList.remove('hidden');
                document.getElementById('start-scan').classList.add('hidden');
                status.textContent = t('scanTableQrHint');
                requestAnimationFrame(scanQrFrame);
            } catch (err) {
                status.textContent = t('cameraPermissionError');
            }
        }

        function stopQrScan() {
            scanningQr = false;
            if (qrStream) {
                qrStream.getTracks().forEach(track => track.stop());
                qrStream = null;
            }
            const video = document.getElementById('qr-video');
            video.srcObject = null;
            document.getElementById('qr-camera').classList.add('hidden');
            document.getElementById('stop-scan').classList.add('hidden');
            document.getElementById('start-scan').classList.remove('hidden');
            document.getElementById('qr-scan-status').textContent = t('scanTableQrHint');
        }

        function scanQrFrame() {
            if (!scanningQr || handlingQr) return;
            const video = document.getElementById('qr-video');
            if (video.readyState === video.HAVE_ENOUGH_DATA && window.jsQR) {
                const canvas = document.getElementById('qr-canvas');
                const width = video.videoWidth;
                const height = video.videoHeight;
                if (width && height) {
                    canvas.width = width;
                    canvas.height = height;
                    const ctx = canvas.getContext('2d', { willReadFrequently: true });
                    ctx.drawImage(video, 0, 0, width, height);
                    const imageData = ctx.getImageData(0, 0, width, height);
                    const result = jsQR(imageData.data, width, height, { inversionAttempts: 'attemptBoth' });
                    if (result && result.data) {
                        handleQrResult(result.data);
                        return;
                    }
                }
            }
            requestAnimationFrame(scanQrFrame);
        }

        async function handleQrResult(text) {
            if (handlingQr) return;
            handlingQr = true;
            const status = document.getElementById('qr-scan-status');
            const code = extractTableCode(text);
            if (!code) {
                status.textContent = t('invalidTableQr');
                setTimeout(() => {
                    handlingQr = false;
                    if (scanningQr) requestAnimationFrame(scanQrFrame);
                }, 1000);
                return;
            }

            status.textContent = t('tableQrDetected');
            try {
                const res = await api('/tables/by-code?code=' + encodeURIComponent(code));
                if (!res.ok) throw new Error('Invalid table');
                const table = await res.json();
                sessionStorage.setItem('selectedTable', table.name || '');
                sessionStorage.setItem('selectedTableCode', code);
                stopQrScan();
                window.location.href = withTab('menu.jsp?tableCode=' + encodeURIComponent(code));
            } catch (err) {
                status.textContent = t('invalidTableQr');
                handlingQr = false;
                if (scanningQr) requestAnimationFrame(scanQrFrame);
            }
        }

        function extractTableCode(text) {
            const raw = String(text || '').trim();
            if (!raw) return '';
            try {
                const parsed = new URL(raw, window.location.href);
                const code = parsed.searchParams.get('tableCode') || parsed.searchParams.get('code');
                if (code) return code.trim();
            } catch (err) {}

            const queryMatch = raw.match(/[?&](?:tableCode|code)=([^&#]+)/i);
            if (queryMatch) return decodeURIComponent(queryMatch[1]).trim();

            const labelMatch = raw.match(/(?:tableCode|code)\s*[:=]\s*([A-Za-z0-9_-]+)/i);
            if (labelMatch) return labelMatch[1].trim();

            return /^TB-[A-Za-z0-9_-]+$/i.test(raw) ? raw : '';
        }

        window.addEventListener('pagehide', stopQrScan);
