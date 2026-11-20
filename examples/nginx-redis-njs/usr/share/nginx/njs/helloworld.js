const PAGE = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>nginx-redis-njs example</title>
</head>
<body>
<p>Hello</p>

<h2>Test pages</h2>
<ul>
<li><a href="/kv/">/kv/</a>: key/value page. Writes go through njs + redis2, reads through HttpRedis or redis2 + njs.</li>
</ul>
</body>
</html>
`;

function index(req) {
    req.log(`Hello from njs!`);
    req.return(200, PAGE);
}

export default {index};
