
float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float scene(vec3 p){
    //sphere SDF
    return sdSphere(p, 2.0);
}

float rayMarch(vec3 ro, vec3 rd, float start, float end){
    float dist = 0.0;
    float d;
    for(int i = 0;i<255;i++){
        //point in space
        vec3 p = ro + rd * dist;
        //collision distance from ray origin
        d = scene(p);
        if(d<0.0001 || dist > end) break;
        dist += max(0.5, 0.2 * d);
    }
    return dist;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / iResolution.y;
    //initializing ray origin and ray direction
    vec3 ro = vec3(0.0, 0.0, -5.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    //background color
    vec3 col = vec3(0.0);
    
    //distance 
    float d = rayMarch(ro, rd, 0.0, 100.0);

    //render a red sphere only if distance < 100 (ray collided)
    if(d<100.0) col = vec3(1.0, 0.0, 0.0);
    
    fragColor = vec4(col,1.0);
}
