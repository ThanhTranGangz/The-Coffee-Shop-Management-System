(function () {
    'use strict';

    var replacements = [
        [/Dashboard panel/g, 'Dashboard'],
        [/Kitchen KDS screen/g, 'KDS pha chế'],
        [/Kitchen KDS/g, 'KDS pha chế'],
        [/Wait station/g, 'Wait station'],
        [/Wait station/g, 'Wait station'],
        [/Khách thành viên/g, 'Khách thành viên'],
        [/Danh sách order/g, 'Danh sách order'],
        [/In mã QR bàn/g, 'In mã QR bàn'],
        [/Kho Nguyên Liệu & Công Thức/g, 'Kho nguyên liệu & công thức'],
        [/Tồn Kho Hiện Tại/g, 'Tồn kho hiện tại'],
        [/Công Thức & Khả Dụng Món/g, 'Công thức & khả dụng món'],
        [/Nhật Ký Nhập Kho/g, 'Nhật ký nhập kho'],
        [/Nhật trình Order & Vận đơn POS/g, 'Nhật trình order & vận đơn POS'],
        [/Chọn đồ uống & Gọi món tại bàn/g, 'Chọn đồ uống & gọi món tại bàn'],
        [/Giao diện khách/g, 'Giao diện khách'],
        [/Quản lý Nhân sự/g, 'Quản lý nhân sự'],
        [/\s{2,}/g, ' ']
    ];

    function cleanText(value) {
        if (!value) return value;
        var next = value;
        replacements.forEach(function (item) {
            next = next.replace(item[0], item[1]);
        });
        return next;
    }

    var LANGUAGE_STORAGE_KEY = 'app_language';
    var appText = {
        vi: {
            close: 'Đóng',
            updated: 'Đã cập nhật.',
            navHome: 'Trang chủ',
            navStaffGate: 'Cổng nhân viên',
            navDashboard: 'Dashboard',
            navReports: 'Doanh số',
            navStaff: 'Nhân sự',
            navInventory: 'Kho hàng',
            navOperations: 'Vận hành',
            navWaitstation: 'Wait station',
            navPos: 'Thu ngân POS',
            navKds: 'KDS pha chế',
            navOrders: 'Danh sách order',
            navQr: 'In mã QR bàn',
            navOrder: 'Gọi món',
            navGuestOrder: 'Khách gọi món',
            navMyOrder: 'Đơn nước của tôi',
            navCheckOrder: 'Kiểm tra đơn nước',
            navMember: 'Khách thành viên',
            roleManager: 'Quản lý',
            roleBarista: 'Pha chế',
            roleWaiter: 'Phục vụ',
            roleMember: 'Member',
            account: 'Tài khoản',
            logout: 'Đăng xuất',
            accessWarning: 'Vui lòng đăng nhập đúng vai trò trước khi sử dụng chức năng này.'
        },
        en: {
            close: 'Close',
            updated: 'Updated.',
            navHome: 'Home',
            navStaffGate: 'Staff gate',
            navDashboard: 'Dashboard',
            navReports: 'Sales',
            navStaff: 'Staff',
            navInventory: 'Inventory',
            navOperations: 'Operations',
            navWaitstation: 'Wait station',
            navPos: 'POS',
            navKds: 'Kitchen display',
            navOrders: 'Orders',
            navQr: 'Table QR',
            navOrder: 'Order',
            navGuestOrder: 'Guest order',
            navMyOrder: 'My order',
            navCheckOrder: 'Check order',
            navMember: 'Member',
            roleManager: 'Manager',
            roleBarista: 'Barista',
            roleWaiter: 'Waiter',
            roleMember: 'Member',
            account: 'Account',
            logout: 'Log out',
            accessWarning: 'Please sign in with the right role before using this feature.'
        }
    };

    function appLanguage() {
        return localStorage.getItem(LANGUAGE_STORAGE_KEY) === 'en' ? 'en' : 'vi';
    }

    function tr(key) {
        var lang = appLanguage();
        return (appText[lang] && appText[lang][key]) || appText.vi[key] || key;
    }

    function setAppLanguage(lang) {
        localStorage.setItem(LANGUAGE_STORAGE_KEY, lang === 'en' ? 'en' : 'vi');
        try {
            window.dispatchEvent(new CustomEvent('app-language-change', { detail: { language: appLanguage() } }));
        } catch (e) {
            return null;
        }
    }

    window.setAppLanguage = setAppLanguage;

    function shouldSkip(node) {
        if (!node || !node.parentElement) return true;
        var tagName = node.parentElement.tagName;
        return tagName === 'SCRIPT' || tagName === 'STYLE' || tagName === 'TEXTAREA' || tagName === 'OPTION';
    }

    function cleanTree(root) {
        if (!root || !document.body) return;
        var walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
            acceptNode: function (node) {
                return shouldSkip(node) ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT;
            }
        });
        var node;
        var changes = [];
        while ((node = walker.nextNode())) {
            var cleaned = cleanText(node.nodeValue);
            if (cleaned !== node.nodeValue) {
                changes.push([node, cleaned]);
            }
        }
        changes.forEach(function (change) {
            change[0].nodeValue = change[1];
        });
    }

    function toastType(message) {
        var text = String(message || '').toLowerCase();
        if (text.indexOf('lỗi') !== -1 || text.indexOf('thất bại') !== -1 || text.indexOf('không') !== -1 || text.indexOf('sai') !== -1) {
            return 'error';
        }
        if (text.indexOf('cảnh báo') !== -1 || text.indexOf('vui lòng') !== -1 || text.indexOf('tạm ngưng') !== -1) {
            return 'warning';
        }
        return 'info';
    }

    function showToast(message, type) {
        if (!document.body) return;
        var stack = document.querySelector('.app-toast-stack');
        if (!stack) {
            stack = document.createElement('div');
            stack.className = 'app-toast-stack';
            document.body.appendChild(stack);
        }

        var toast = document.createElement('div');
        toast.className = 'app-toast';
        toast.setAttribute('data-type', type || toastType(message));
        toast.innerHTML =
            '<span class="app-toast-dot" aria-hidden="true"></span>' +
            '<div class="app-toast-message"></div>' +
            '<button type="button" class="app-toast-close" aria-label="' + tr('close') + '">×</button>';
        toast.querySelector('.app-toast-message').textContent = cleanText(String(message || tr('updated')));
        toast.querySelector('.app-toast-close').addEventListener('click', function () {
            toast.remove();
        });
        stack.appendChild(toast);

        window.setTimeout(function () {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(6px)';
            window.setTimeout(function () {
                toast.remove();
            }, 180);
        }, 3600);
    }

    function installAlertToast() {
        window.appToast = showToast;
        window.alert = function (message) {
            showToast(message, toastType(message));
        };
    }

    function pageName() {
        var path = window.location.pathname || '';
        return path.substring(path.lastIndexOf('/') + 1) || 'index.html';
    }

    function navClass(href) {
        var current = pageName();
        var active = current === href;
        return 'hover:text-coffee-rust transition-colors ' + (active ? 'text-coffee-dark font-bold' : 'text-coffee-milk');
    }

    function navLink(href, label, extraClass) {
        return '<a href="' + href + '" class="' + navClass(href) + (extraClass ? ' ' + extraClass : '') + '">' + label + '</a>';
    }

    function currentMemberPhone() {
        return localStorage.getItem('member_phone') || '';
    }

    function dropdown(label, links) {
        var items = links.map(function (item) {
            return '<a href="' + item.href + '" class="block px-4 py-2 hover:bg-coffee-light text-coffee-dark hover:text-coffee-rust transition-colors">' + item.label + '</a>';
        }).join('');
        return '<div class="relative group">' +
            '<button class="bg-coffee-light hover:bg-coffee-sand/30 text-coffee-dark border border-coffee-sand px-3 py-1 rounded-lg flex items-center gap-1 cursor-pointer">' +
            '<span>' + label + '</span>' +
            '<svg class="w-3 h-3 text-coffee-rust" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>' +
            '</button>' +
            '<div class="absolute left-0 mt-1 w-56 bg-white border border-coffee-sand rounded-xl shadow-lg py-1.5 hidden group-hover:block z-50">' +
            items +
            '</div>' +
            '</div>';
    }

    function roleNavigation(role) {
        var current = pageName();
        var authPages = ['login.jsp', 'pin-login.jsp', 'staff.html'];
        if (authPages.indexOf(current) !== -1) {
            return [
                navLink('index.html', tr('navHome')),
                navLink('staff.html', tr('navStaffGate'))
            ].join('');
        }

        if (role === 'manager') {
            return [
                navLink('dashboard.jsp', tr('navDashboard')),
                navLink('reports.jsp', tr('navReports')),
                navLink('staff-management.jsp', tr('navStaff')),
                navLink('inventory.jsp', tr('navInventory')),
                dropdown(tr('navOperations'), [
                    { href: 'waitstation.jsp', label: tr('navWaitstation') },
                    { href: 'pos-payment.jsp', label: tr('navPos') },
                    { href: 'kds.jsp', label: tr('navKds') },
                    { href: 'staff-orders.jsp', label: tr('navOrders') },
                    { href: 'table-qr.jsp', label: tr('navQr') }
                ])
            ].join('');
        }

        if (role === 'waiter') {
            return [
                navLink('waitstation.jsp', tr('navWaitstation'), 'font-semibold'),
                navLink('pos-payment.jsp', tr('navPos')),
                navLink('staff-orders.jsp', tr('navOrders')),
                navLink('table-qr.jsp', tr('navQr'))
            ].join('');
        }

        if (role === 'barista') {
            return [
                navLink('kds.jsp', tr('navKds'), 'font-semibold')
            ].join('');
        }

        if (currentMemberPhone()) {
            return [
                navLink('menu.jsp', tr('navOrder'), 'font-semibold'),
                navLink('order-status.jsp', tr('navMyOrder')),
                navLink('member.jsp', tr('navMember'))
            ].join('');
        }

        return [
            navLink('index.html', tr('navHome')),
            navLink('menu.jsp', tr('navGuestOrder'), 'font-semibold'),
            navLink('order-status.jsp', tr('navCheckOrder'))
        ].join('');
    }

    function applyRoleNavigation() {
        var navContainer = document.querySelector('nav div.hidden.lg\\:flex');
        if (!navContainer) return;
        var role = localStorage.getItem('auth_role') || '';
        navContainer.innerHTML = roleNavigation(role);
    }

    function syncSessionFromServer() {
        return fetch('api/auth/session', {
            credentials: 'same-origin'
        }).then(function (response) {
            return response.ok ? response.json() : null;
        }).then(function (data) {
            if (!data) return;

            if (data.authenticated && data.role) {
                localStorage.setItem('auth_role', data.role);
                localStorage.setItem('auth_user', data.user || data.username || 'Tài khoản');
                localStorage.removeItem('member_phone');
                localStorage.removeItem('member_name');
            } else {
                localStorage.removeItem('auth_role');
                localStorage.removeItem('auth_user');
            }

            if (data.memberAuthenticated && data.memberPhone) {
                localStorage.setItem('member_phone', data.memberPhone);
                localStorage.setItem('member_name', data.memberName || data.memberPhone);
            } else if (!data.authenticated) {
                localStorage.removeItem('member_phone');
                localStorage.removeItem('member_name');
            }
        }).catch(function () {
            return null;
        });
    }

    function installAccessGuard() {
        var protectedPages = {
            'dashboard.jsp': ['manager'],
            'reports.jsp': ['manager'],
            'staff-management.jsp': ['manager'],
            'inventory.jsp': ['manager'],
            'waitstation.jsp': ['waiter', 'manager'],
            'staff-orders.jsp': ['waiter', 'manager'],
            'table-qr.jsp': ['waiter', 'manager'],
            'order-summary.jsp': ['waiter', 'manager'],
            'pos-payment.jsp': ['waiter', 'manager'],
            'kds.jsp': ['barista', 'manager']
        };

        document.addEventListener('click', function (event) {
            var link = event.target.closest ? event.target.closest('a[href]') : null;
            if (!link) return;

            var href = link.getAttribute('href') || '';
            var file = href.split('?')[0].split('#')[0].split('/').pop();
            var allowedRoles = protectedPages[file];
            if (!allowedRoles) return;

            var role = localStorage.getItem('auth_role') || '';
            if (!role) return;
            if (allowedRoles.indexOf(role) === -1) {
                event.preventDefault();
                showToast(tr('accessWarning'), 'warning');
                window.setTimeout(function () {
                    window.location.href = 'login.jsp';
                }, 350);
            }
        }, true);
    }

    function installLogoutHandler() {
        window.handleLocalLogout = function () {
            localStorage.removeItem('auth_role');
            localStorage.removeItem('auth_user');
            fetch('api/auth/logout', {
                method: 'POST',
                credentials: 'same-origin',
                keepalive: true
            }).catch(function () {
                return null;
            }).finally(function () {
                window.location.href = 'index.html';
            });
        };

        window.handleMemberLogout = function () {
            localStorage.removeItem('member_phone');
            localStorage.removeItem('member_name');
            fetch('api/members/logout', {
                method: 'POST',
                credentials: 'same-origin',
                keepalive: true
            }).catch(function () {
                return null;
            }).finally(function () {
                window.location.href = 'index.html';
            });
        };
    }

    function renderSessionControls() {
        document.querySelectorAll('.app-session-control').forEach(function (node) {
            node.remove();
        });

        var role = localStorage.getItem('auth_role') || '';
        var memberPhone = currentMemberPhone();
        if (!role && !memberPhone) return;

        var user = localStorage.getItem('auth_user') || tr('account');
        var memberName = localStorage.getItem('member_name') || memberPhone;
        var roleLabel = role ? (role === 'manager' ? tr('roleManager') : role === 'barista' ? tr('roleBarista') : tr('roleWaiter')) : tr('roleMember');
        var accountLabel = role ? user : memberName;
        var logoutHandler = role ? 'handleLocalLogout()' : 'handleMemberLogout()';
        var holder = document.querySelector('header .flex.items-center.gap-3\\.5') ||
            document.querySelector('nav div.flex.items-center.gap-3') ||
            document.querySelector('nav > div') ||
            document.body;

        var control = document.createElement('div');
        control.className = 'app-session-control';
        control.innerHTML =
            '<div class="app-session-badge">' +
                '<span class="app-session-dot"></span>' +
                '<span class="app-session-text">' + roleLabel + ': ' + accountLabel + '</span>' +
            '</div>' +
            '<button type="button" class="app-session-logout" onclick="' + logoutHandler + '">' + tr('logout') + '</button>';
        holder.appendChild(control);
    }

    function renderLanguageSwitch() {
        document.querySelectorAll('.app-language-control').forEach(function (node) {
            node.remove();
        });
        if (pageName() === 'menu.jsp') return;

        var holder = document.querySelector('header .flex.items-center.gap-3\\.5') ||
            document.querySelector('nav div.flex.items-center.gap-3') ||
            document.querySelector('nav > div') ||
            document.body;
        var lang = appLanguage();
        var activeClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all bg-coffee-rust text-white shadow-xs';
        var idleClass = 'text-[10px] font-bold px-2 py-1 rounded-full transition-all text-coffee-milk hover:text-coffee-rust';
        var control = document.createElement('div');
        control.className = 'app-language-control flex items-center gap-1 bg-white border border-coffee-sand rounded-full p-0.5 shadow-xs';
        control.innerHTML =
            '<button type="button" onclick="setAppLanguage(&quot;vi&quot;)" class="' + (lang === 'vi' ? activeClass : idleClass) + '">VI</button>' +
            '<button type="button" onclick="setAppLanguage(&quot;en&quot;)" class="' + (lang === 'en' ? activeClass : idleClass) + '">EN</button>';
        holder.appendChild(control);
    }

    function redirectLoggedMemberFromHome() {
        if (localStorage.getItem('auth_role')) return;
        if (!currentMemberPhone()) return;
        var current = pageName();
        var publicEntryPages = ['index.html', 'staff.html', 'login.jsp', 'pin-login.jsp'];
        if (publicEntryPages.indexOf(current) !== -1) {
            window.location.replace('member.jsp');
        }
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.documentElement.lang = appLanguage();
        document.body.classList.add('app-polished');
        cleanTree(document.body);
        installAlertToast();
        installLogoutHandler();
        installAccessGuard();

        syncSessionFromServer().then(function () {
            applyRoleNavigation();
            redirectLoggedMemberFromHome();
            renderSessionControls();
            renderLanguageSwitch();
        });
        window.setTimeout(renderSessionControls, 250);
        window.setTimeout(renderLanguageSwitch, 250);
        window.addEventListener('app-language-change', function () {
            document.documentElement.lang = appLanguage();
            applyRoleNavigation();
            renderSessionControls();
            renderLanguageSwitch();
        });

        var observer = new MutationObserver(function (mutations) {
            mutations.forEach(function (mutation) {
                if (mutation.type === 'characterData' && !shouldSkip(mutation.target)) {
                    var cleanedText = cleanText(mutation.target.nodeValue);
                    if (cleanedText !== mutation.target.nodeValue) {
                        mutation.target.nodeValue = cleanedText;
                    }
                    return;
                }
                mutation.addedNodes.forEach(function (node) {
                    if (node.nodeType === Node.TEXT_NODE && !shouldSkip(node)) {
                        node.nodeValue = cleanText(node.nodeValue);
                    } else if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== 'SCRIPT' && node.tagName !== 'STYLE') {
                        cleanTree(node);
                    }
                });
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true
        });
    });
})();
