function index(req) {
    req.log(`Hello from njs!`);
    req.return(200, "Hello\n");
}

export default {index};
