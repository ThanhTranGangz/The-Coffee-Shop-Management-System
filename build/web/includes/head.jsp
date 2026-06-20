<%@page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    if (pageTitle == null || pageTitle.isEmpty()) {
        pageTitle = "nhà cà phê";
    }
    if (ctx == null || ctx.isEmpty()) {
        ctx = request.getContextPath();
    }
%>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#f4eee1">
<title><%= pageTitle %></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/assets/css/app.css">
