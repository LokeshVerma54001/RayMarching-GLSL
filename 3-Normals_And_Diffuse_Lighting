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

mat3 identity(){
    return mat3(
        vec3(1, 0, 0),
        vec3(0, 1, 0),
        vec3(0, 0, 1)
    );
}

struct Surface{
    float sd;
    vec3 sc;
    //surface distance and surface color
};

Surface sdPlane(vec3 p, vec3 offset, vec3 col){
    p -= offset;
    float d = p.y + 1.0;
    return Surface(d, col);
}

Surface sdSphere(vec3 p, float r, vec3 offset, vec3 col){
    p-=offset;
    float d = length(p) - r;
    return Surface(d, col);
}

Surface sdBox(vec3 p, vec3 size, vec3 offset, vec3 col){
    p -= offset;
    vec3 q = abs(p) - size;
    float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    return Surface(d, col);
}

Surface minWithColor(Surface obj1, Surface obj2){
    if(obj1.sd < obj2.sd) return obj1;
    return obj2;
}

Surface scene(vec3 p){
    //sphere SDF
    Surface d1 = sdSphere(p, 2.0, vec3(-2.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0));
    Surface d2 = sdBox(p, vec3(1.0), vec3(3.0, 0.0, 0.0), vec3(0.0, 0.0, 1.0));
    Surface d3 = sdPlane(p, vec3(0.0, -1.0, 0.0), vec3(0.0, 1.0, 0.0));
    Surface co = minWithColor(d1, d2);
    return minWithColor(co, d3);
}

Surface rayMarch(vec3 ro, vec3 rd, float start, float end){
    float dist = 0.0;
    Surface co;
    for(int i = 0;i<255;i++){
        //point in space
        vec3 p = ro + rd * dist;
        //collision distance from ray origin
        co = scene(p);
        if(co.sd<0.0001 || dist > end) break;
        dist += co.sd;
    }
    return Surface(dist, co.sc);
}

vec3 getNormals(vec3 p){
    vec2 e = vec2(0.001, 0);
    vec3 n = vec3(
        scene(p + e.xyy).sd - scene(p - e.xyy).sd,
        scene(p + e.yxy).sd - scene(p - e.yxy).sd,
        scene(p + e.yyx).sd - scene(p - e.yyx).sd
    );
    return normalize(n);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;
    //initializing ray origin and ray direction
    vec3 ro = vec3(0.0, 0.0, -5.0);
    //camera setup
    vec3 front = normalize(vec3(0.0, 0.0, 1.0));
    vec3 right = normalize(cross(front, vec3(0.0, -1.0, 0.0)));
    vec3 up = normalize(cross(front, right));
    mat3 lookAtMat = mat3(right, up, front);
    vec3 rd = lookAtMat * normalize(vec3(uv, 1.0));
    //background color
    vec3 col = vec3(0.0);
    
    //distance 
    Surface co = rayMarch(ro, rd, 0.0, 100.0);

    //render a red sphere only if distance < 100 (ray collided)
    if(co.sd<100.0){
        vec3 p = ro + rd * co.sd;
        vec3 normal = getNormals(p);
        
        //light
        vec3 lo = vec3(cos(iTime) * 5.0, 2.0,  sin(iTime) *5.0);
        vec3 ld = normalize(lo - p);
        
        float diffuse = max(dot(ld, normal), 0.0);
        
        col = co.sc * diffuse;
    }
    
    fragColor = vec4(col,1.0);
}
