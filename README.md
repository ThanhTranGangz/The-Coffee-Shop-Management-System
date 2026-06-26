# The Coffee Shop Management System Lite

This is a simplified Java Servlet/JSP version of the coffee shop system.

## Scope

- Guest table ordering
- Order status lookup
- Staff order processing
- Admin dashboard
- Admin menu CRUD
- Admin table and QR management
- Vietnamese/English UI toggle

## Demo Accounts

| Role | Username | Password |
| --- | --- | --- |
| Admin | `admin` | `123456` |
| Barista | `barista` | `123456` |
| Cashier | `cashier` | `123456` |

## Database

The app auto-creates SQL Server database `CoffeeShopLite` on first API call.

Connection defaults:

- Server: `localhost`
- Port: `1433`
- User: `sa`
- Password: `123`

Main initializer:

```text
src/java/service/LiteService.java
```

Connection class:

```text
src/java/context/DBContext.java
```

## Pages

| Page | Purpose |
| --- | --- |
| `index.html` | Landing / portal |
| `staff-login.jsp` | Admin/staff login |
| `menu.jsp` | Guest ordering from table QR |
| `order-status.jsp` | Guest order lookup |
| `staff-orders.jsp` | Staff order processing |
| `dashboard.jsp` | Admin overview |
| `admin-tables.jsp` | Table and QR CRUD |
| `admin-menu.jsp` | Menu CRUD |

## Build

```bash
ant dist
```

NetBeans can open this folder directly:

```text
The-Coffee-Shop-Management-System-Lite
```
