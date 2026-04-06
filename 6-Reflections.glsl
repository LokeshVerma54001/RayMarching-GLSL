mat3 rotateX(float theta){
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float theta){
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float theta){
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

struct Surface{
    float sd;
    vec3 sc;
};

Surface sdPlane(vec3 p, vec3 offset, vec3 col){
    p -= offset;
    float d = p.y + 1.0;
    return Surface(d, col);
}

Surface sdSphere(vec3 p, float r, vec3 offset, vec3 col){
    p -= offset;
    float d = length(p) - r;
    return Surface(d, col);
}

Surface sdBox(vec3 p, vec3 size, vec3 offset, vec3 col){
    p -= offset;
    vec3 q = abs(p) - size;
    float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    return Surface(d, col);
}

Surface minWithColor(Surface a, Surface b){
    if(a.sd<b.sd) return a;
    return b;
}

Surface scene(vec3 p){
    Surface d1 = sdSphere(p, 2.0, vec3(-2.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0));
    Surface d2 = sdBox(p, vec3(1.0), vec3(3.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0));
    Surface d3 = sdPlane(p, vec3(0.0, -1.0, 0.0), vec3(0.0, 1.0, 0.0));
    return minWithColor(minWithColor(d1, d2), d3);
}

Surface rayMarch(vec3 ro, vec3 rd, float start, float end){
    float dist = start;
    Surface co;

    for(int i = 0; i < 255; i++){
        vec3 p = ro + rd * dist;
        co = scene(p);

        if(co.sd < 0.0001) return Surface(dist, co.sc);
        if(dist > end) break;

        dist += co.sd;
    }

    return Surface(end, vec3(0.0)); // no hit
}

float softShadow(vec3 ro, vec3 rd, float mint, float tmax){
    float res = 1.0;
    float t = mint;

    for(int i = 0; i < 128; i++){
        float h = scene(ro + rd * t).sd;
        if(h < 0.001) return 0.0;

        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);

        if(t > tmax) break;
    }

    return clamp(res, 0.0, 1.0);
}

vec3 getNormals(vec3 p){
    vec2 e = vec2(0.001, 0);
    return normalize(vec3(
        scene(p + e.xyy).sd - scene(p - e.xyy).sd,
        scene(p + e.yxy).sd - scene(p - e.yxy).sd,
        scene(p + e.yyx).sd - scene(p - e.yyx).sd
    ));
}

vec3 sky(vec3 rd){
    return vec3(0.5, 0.7, 1.0) * (0.5 + 0.5 * rd.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0.0, 0.0, -5.0);

    vec3 front = normalize(vec3(0.0, 0.0, 1.0));
    vec3 right = normalize(cross(front, vec3(0.0, -1.0, 0.0)));
    vec3 up = normalize(cross(front, right));

    mat3 cam = mat3(right, up, front);
    vec3 rd = cam * normalize(vec3(uv, 1.0));

    vec3 col = vec3(0.0);

    Surface hit = rayMarch(ro, rd, 0.0, 100.0);

    if(hit.sd < 100.0){
        vec3 p = ro + rd * hit.sd;
        vec3 n = getNormals(p);

        vec3 lo = vec3(cos(iTime) * 5.0, 2.0, sin(iTime) * 5.0);
        vec3 ld = normalize(lo - p);

        float diff = max(dot(n, ld), 0.0);
        float shadow = softShadow(p + n * 0.001, ld, 0.02, 10.0);

        vec3 base = hit.sc * (0.2 + diff * shadow);

        // -------- Reflection --------
        vec3 reflDir = reflect(rd, n);
        float bias = max(0.001, 0.001 * hit.sd);
        vec3 reflOrigin = p + n * bias;

        Surface reflHit = rayMarch(reflOrigin, reflDir, 0.0, 100.0);

        vec3 reflCol;

        if(reflHit.sd < 100.0){
            vec3 rp = reflOrigin + reflDir * reflHit.sd;
            vec3 rn = getNormals(rp);

            vec3 rld = normalize(lo - rp);
            float rdiff = max(dot(rn, rld), 0.0);
            float rshadow = softShadow(rp + rn * 0.001, rld, 0.02, 10.0);

            reflCol = reflHit.sc * (0.2 + rdiff * rshadow);
        } else {
            reflCol = sky(reflDir);
        }

        // Fresnel
        float fresnel = pow(1.0 - max(dot(-rd, n), 0.0), 5.0);
        float reflectivity = mix(0.1, 0.7, fresnel);

        col = base * (1.0 - reflectivity) + reflCol * reflectivity;
    } else {
        col = sky(rd);
    }

    fragColor = vec4(col, 1.0);
}
