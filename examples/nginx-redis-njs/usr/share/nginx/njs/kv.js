// Key/value example: writes and redis2 reads.
// HttpRedis reads need no njs; see /api/hr in etc/nginx/conf.d/10_helloworld.conf.

import qs from 'querystring';

const KEY_RE = /^[A-Za-z0-9_.-]{1,64}$/;
const KEY_HINT = 'key: 1-64 characters, letters, digits, . _ -';
const MAX_VALUE_BYTES = 1024;
const TTL_SECONDS = 3600;

// js_set $redis_password. Needs "env REDIS_PASSWORD;" in nginx.conf.
function redis_password(r) {
    return process.env.REDIS_PASSWORD || '';
}

function reply(r, status, text) {
    r.headersOut['Content-Type'] = 'text/plain; charset=utf-8';
    r.return(status, text + '\n');
}

// Refuse cross-site form posts (CSRF). Browsers send these headers; curl does not.
function sameOrigin(r) {
    const site = r.headersIn['Sec-Fetch-Site'];
    if (site && site !== 'same-origin' && site !== 'none') {
        return false;
    }
    const origin = r.headersIn['Origin'];
    if (origin && origin !== `${r.variables.scheme}://${r.headersIn['Host']}`) {
        return false;
    }
    return true;
}

// redis2 returns raw Redis protocol replies, one per query in the pipeline:
// +OK  -ERR ...  :123  $5\r\nhello  $-1 (missing key).
// Bulk lengths are in bytes, so parse the Buffer, not the decoded text.
function parseReplies(buf) {
    const replies = [];
    let pos = 0;
    while (pos < buf.length) {
        const eol = buf.indexOf('\r\n', pos);
        if (eol < 0) {
            break;
        }
        const type = String.fromCharCode(buf[pos]);
        const line = buf.slice(pos + 1, eol).toString();
        pos = eol + 2;
        if (type === '$') {
            const len = parseInt(line, 10);
            if (len < 0) {
                replies.push({ type, value: null });
                continue;
            }
            replies.push({ type, value: buf.slice(pos, pos + len).toString() });
            pos += len + 2;
        } else {
            replies.push({ type, value: line });
        }
    }
    return replies;
}

// POST /api/kv  (form fields: key, value)
async function write(r) {
    if (r.method !== 'POST') {
        return reply(r, 405, 'use POST');
    }
    if (!sameOrigin(r)) {
        return reply(r, 403, 'cross-site request refused');
    }
    if (!(r.headersIn['Content-Type'] || '').startsWith('application/x-www-form-urlencoded')) {
        return reply(r, 415, 'expected a form post');
    }

    const form = qs.parse(r.requestText || '');
    if (typeof form.key !== 'string' || !KEY_RE.test(form.key)) {
        return reply(r, 400, KEY_HINT);
    }
    if (typeof form.value !== 'string') {
        return reply(r, 400, 'value is missing');
    }
    if (Buffer.byteLength(form.value) > MAX_VALUE_BYTES) {
        return reply(r, 413, `value: at most ${MAX_VALUE_BYTES} bytes`);
    }

    r.variables.kv_key = `demo:${form.key}`;
    r.variables.kv_value = form.value;
    r.variables.kv_ttl = String(TTL_SECONDS);

    const res = await r.subrequest('/_redis2/set');
    const replies = parseReplies(res.responseBuffer || Buffer.from(''));
    // replies[0] answers AUTH, replies[1] answers SET
    if (res.status !== 200 || !replies[1] || replies[1].type !== '+') {
        r.error(`redis2 SET failed: ${res.status} ${JSON.stringify(res.responseText)}`);
        return reply(r, 502, 'redis error');
    }

    reply(r, 200, `saved demo:${form.key}, expires in ${TTL_SECONDS} s`);
}

// GET /api/r2?key=...
async function read(r) {
    const key = r.args.key;
    if (typeof key !== 'string' || !KEY_RE.test(key)) {
        return reply(r, 400, KEY_HINT);
    }

    r.variables.kv_key = `demo:${key}`;

    const res = await r.subrequest('/_redis2/get');
    const replies = parseReplies(res.responseBuffer || Buffer.from(''));
    // replies[0] answers AUTH, replies[1] answers GET, replies[2] answers TTL
    const value = replies[1];
    const ttl = replies[2];
    if (res.status !== 200 || !value || value.type !== '$') {
        r.error(`redis2 GET failed: ${res.status} ${JSON.stringify(res.responseText)}`);
        return reply(r, 502, 'redis error');
    }
    if (value.value === null) {
        return reply(r, 404, 'not found');
    }

    reply(r, 200, [
        value.value,
        '',
        '-- module: redis2 + njs',
        `-- ttl:    ${ttl ? ttl.value : '?'} s`,
        `-- raw:    ${JSON.stringify(res.responseText)}`,
    ].join('\n'));
}

export default { redis_password, write, read };
