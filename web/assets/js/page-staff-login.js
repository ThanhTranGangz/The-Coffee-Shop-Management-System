        let selectedRole = 'barista';

        document.addEventListener('DOMContentLoaded', () => {
            applyI18n();
            document.getElementById('pin').focus();
        });

        function chooseRole(role) {
            selectedRole = role;
            document.querySelectorAll('.role-option').forEach(btn => btn.classList.toggle('active', btn.dataset.role === role));
            document.getElementById('pin').focus();
        }

        document.getElementById('login-form').addEventListener('submit', async (event) => {
            event.preventDefault();
            const res = await api('/auth/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    username: selectedRole,
                    password: document.getElementById('pin').value
                })
            });
            if (res.ok) {
                const user = await res.json();
                const targetByRole = {
                    barista: 'staff-orders.jsp',
                    cashier: 'cashier.jsp',
                    runner: 'runner.jsp'
                };
                const target = targetByRole[user.role] || 'staff-login.jsp';
                window.location.href = target;
            } else {
                const err = await res.json().catch(() => ({}));
                const box = document.getElementById('message');
                box.textContent = err.error || t('loginFailed');
                box.classList.remove('hidden');
            }
        });
