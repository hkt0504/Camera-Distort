
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

/////// Video Display Shader ////////
NSString *const g_VideoVertexShaderStr = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

NSString *const g_VideoFragmentShaderStr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

#else

NSString *const g_VideoFragmentShaderStr = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );
#endif

////////// Color Swizzling Shader Language ////////////////////
NSString *const g_ColorSwizzlingVertexShaderStr = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

NSString *const g_ColorSwizzlingFragmentShaderStr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = textureColor;
 }
 );

#else

NSString *const g_ColorSwizzlingFragmentShaderStr = SHADER_STRING
(
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = vec4(textureColor.b, textureColor.g, textureColor.r, textureColor.a);
 }
 );
#endif

////// Distortion Effect Shader //////
NSString *const g_DistortionEffectVertexShaderStr = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate1;
 varying vec2 v_texCoord;
 
 void main()
 {
     gl_Position = position;
     v_texCoord = inputTextureCoordinate1.xy;
 }
);

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const g_DistortionEffectFragmentShaderStr = SHADER_STRING
(
 precision highp float;
 uniform sampler2D effect_tex;
 varying vec2 v_texCoord;
 uniform float fx;
 uniform float fy;
 uniform float cx;
 uniform float cy;
 uniform float k1;
 uniform float k2;
 uniform float k3;
 uniform float p1;
 uniform float p2;
 uniform float xrate;
 uniform float yrate;
 uniform float skew;
 uniform float zoom;
 void main(){
     float y = (v_texCoord.y * yrate-cy)/fy;
     float x = (v_texCoord.x * xrate-cx)/fx - skew*y;
     float r2 = x*x + y*y;
     float radial_d = 1.0 + k1*r2 + k2*r2*r2 + k3*r2*r2*r2;
     float x_d = radial_d*x + 2.0*p1*x*y + p2*(r2 + 2.0*x*x);
     float y_d = radial_d*y + p1*(r2 + 2.0*y*y) + 2.0*p2*x*y;
     x = (fx*(x_d + skew*y_d) + cx) / xrate;
     y = (fy*y_d + cy) / yrate;
    
     if(x < 0.0 || y < 0.0 || x > 1.0 || y > 1.0)
         gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
     else
     {
         gl_FragColor = texture2D(effect_tex, vec2(x, y));
     }
 }
);

NSString *const g_DistortionFishEyeEffectFragmentShaderStr = SHADER_STRING
(
 precision highp float;
 uniform sampler2D effect_tex;
 varying vec2 v_texCoord;
 uniform float fx;
 uniform float fy;
 uniform float cx;
 uniform float cy;
 uniform float k1;
 uniform float k2;
 uniform float p1;
 uniform float p2;
 uniform float zoom;
 uniform float m1;
 uniform float m2;
 uniform float m3;
 uniform float m4;
 uniform float distort;
 void main(){
     
     float y = (v_texCoord.y - cy)/fy;
     float x = (v_texCoord.x - cx)/fx;
     float r1 = sqrt(x*x + y*y);
     float x_d = x*atan(2.0*r1*tan(k2/2.0))/(k1+abs(x)*m1+r1*m2)/r1;
     float y_d = y*atan(2.0*r1*tan(p2/2.0))/(p1+abs(y)*m3+r1*m4)/r1;
     
     if (distort < 1.0)
     {
         x_d = x_d * distort + x * (1.0-distort);
         y_d = y_d * distort + y * (1.0-distort);
     }
     x = fx*x_d + cx;
     y = fy*y_d + cy;
     
     if(x < 0.0 || y < 0.0 || x > 1.0 || y > 1.0)
         gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
     else
     {
         gl_FragColor = texture2D(effect_tex, vec2(x, y));
     }
 }
 );

#endif
#ifdef __cplusplus
};
#endif

////////////////////////////////////////////////////////





