
#include "ffopengles2.h"

// image texture
GLuint	g_ImageVertexShader;
GLuint	g_ImageFragmentShader, g_DrawFragmentShader;
GLuint	g_ImageProgram, g_DrawProgram;
GLuint	g_vImagePositionHandle, g_vImageTexPos, g_ImageTexture;
GLuint	g_vDrawPositionHandle, g_vDrawTexPos, g_texDrawLoc;
GLint	g_texImageLoc;
int		g_nImageWidth = 0;
int 	g_nImageHeight = 0;

GLuint	g_FrameBuff;
GLuint	g_FrameTexture;
int		g_FrameCreated = 0;

static const char g_VertexShaderStr[] = 
"attribute vec4 vPosition;    \n"  
"attribute vec2 a_texCoord;   \n"  
"varying vec2 tc;     \n"  
"void main()                  \n"  
"{                            \n"  
"   gl_Position = vPosition;  \n"  
"   tc = a_texCoord;  \n"  
"}                            \n";  

static const char g_DrawFragmentShaderStr[] =
"precision mediump float;\n"
"uniform sampler2D effect_tex;\n"
"varying vec2 tc;\n"
"void main(){\n"
"gl_FragColor = texture2D(effect_tex, tc);\n"
"}\n";

static const char g_FragmentShaderStr[] =
"precision highp float;\n"
"uniform sampler2D effect_tex;\n"
"varying vec2 tc;\n"
"uniform float fx;\n"
"uniform float fy;\n"
"uniform float cx;\n"
"uniform float cy;\n"
"uniform float k1;\n"
"uniform float k2;\n"
"uniform float p1;\n"
"uniform float p2;\n"
"uniform float m1;\n"
"uniform float m2;\n"
"uniform float m3;\n"
"uniform float m4;\n"
"uniform float zoom;\n"
"uniform float distort;\n"
"void main(){\n"
"float y = (tc.y-cy)/fy;\n"
"float x = (tc.x-cx)/fx;\n"
"float r1 = sqrt(x*x + y*y);\n"
"float x_d = x*atan(2.0*r1*tan(k2/2.0))/(k1+abs(x)*m1+r1*m2)/r1;\n"
"float y_d = y*atan(2.0*r1*tan(p2/2.0))/(p1+abs(y)*m3+r1*m4)/r1;\n"
"if (distort < 1.0) {\n"
"x_d = x_d * distort + x * (1.0-distort);\n"
"y_d = y_d * distort + y * (1.0-distort);\n"
"}\n"
"x = fx*x_d + cx;\n"
"y = fy*y_d + cy;\n"
"if ((x<0.0)||(y<0.0)||(x>1.0)||(y>1.0))\n"
"	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);\n"
"else\n"
"	gl_FragColor = texture2D(effect_tex, vec2(x, y)); \n"
"}\n";

GLuint LoadShader(GLenum type, const char *shaderSrc)
{
	GLuint shader;
	GLint compiled;

	// Create the shader object
	shader = glCreateShader(type);

	if(shader == 0)
		return 0;

	// Load the shader source
	glShaderSource(shader, 1, &shaderSrc, NULL);

	//Compile the shader
	glCompileShader(shader);

	// Check the compile status
	glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

	if(!compiled)
	{
		glDeleteShader(shader);
		return 0;
	}
	return shader;
}

GLuint CreateProgram(GLuint vertexShader, GLuint fragmentShader)
{
	GLuint programObject;
	GLint linked;

	// Create the program object
	programObject = glCreateProgram();

	if(programObject == 0)
		return 0;

	glAttachShader(programObject, vertexShader);
	glAttachShader(programObject, fragmentShader);

	// Link the program
	glLinkProgram(programObject);

	// Check the link status
	glGetProgramiv(programObject, GL_LINK_STATUS, &linked);

	if(!linked)
	{
		glDeleteProgram(programObject);
		return 0;
	}
	return programObject;
}

void CreateImageTexture(int saveFlag, int nWidth, int nHeight)
{
	if(g_nImageWidth != 0 || g_nImageHeight != 0)
		glDeleteTextures(1, &g_ImageTexture);

	glGenTextures(1, &g_ImageTexture);
	glBindTexture(GL_TEXTURE_2D, g_ImageTexture);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nWidth, nHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, NULL);

	if (saveFlag)
	{
		if (g_FrameCreated)
		{
			glDeleteTextures(1, &g_FrameTexture);
			glDeleteFramebuffers(1, &g_FrameBuff);
		}

		glGenFramebuffers(1, &g_FrameBuff);
		glBindFramebuffer(GL_FRAMEBUFFER, g_FrameBuff);
		glGenTextures(1, &g_FrameTexture);
		glBindTexture(GL_TEXTURE_2D, g_FrameTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
		glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nWidth, nHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, NULL);
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, g_FrameTexture, 0);

		g_FrameCreated = 1;
	}

	g_nImageWidth = nWidth;
	g_nImageHeight = nHeight;
}

void OnGLESRender(int saveFlag, char *pSrcBuffer, int nWidth, int nHeight)
{
	CreateImageTexture(saveFlag, nWidth, nHeight);

	if (saveFlag)
	{
		glViewport(0, 0, nWidth, nHeight);
		glBindFramebuffer(GL_FRAMEBUFFER, g_FrameBuff);
	}
	else
	{
		glViewport(0, 0, glScreenW, glScreenH);
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}

	glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(g_ImageProgram);

    float texs[] = { 0, 0, 0, 1, 1, 0, 1, 1};
    float vtCoord[] = { -1, 1, -1, -1, 1, 1, 1, -1};
    if (zoomScale < 1.0f)
    {
    	vtCoord[0] = -zoomScale;
    	vtCoord[1] = zoomScale;
    	vtCoord[2] = -zoomScale;
    	vtCoord[3] = -zoomScale;
    	vtCoord[4] = zoomScale;
    	vtCoord[5] = zoomScale;
    	vtCoord[6] = zoomScale;
    	vtCoord[7] = -zoomScale;
    }
    else
    {
        texs[0] = 0.5 * (zoomScale / 2 - 0.5);
        texs[1] = 0.5 * (zoomScale / 2 - 0.5);
        texs[2] = 0.5 * (zoomScale / 2 - 0.5);
        texs[3] = 0.5 * (2.5 - zoomScale / 2);
        texs[4] = 0.5 * (2.5 - zoomScale / 2);
        texs[5] = 0.5 * (zoomScale / 2 - 0.5);
        texs[6] = 0.5 * (2.5 - zoomScale / 2);
        texs[7] = 0.5 * (2.5 - zoomScale / 2);
    }

	glVertexAttribPointer(g_vImagePositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vtCoord);
	glEnableVertexAttribArray(g_vImagePositionHandle);
	glVertexAttribPointer(g_vImageTexPos, 2, GL_FLOAT, GL_FALSE, 0, texs);
	glEnableVertexAttribArray(g_vImageTexPos);

	glBindTexture(GL_TEXTURE_2D, g_ImageTexture);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nWidth, nHeight, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, pSrcBuffer);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );

	glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, g_ImageTexture);

	glUniform1i(g_texImageLoc, 5);

    distortion_param_t param = get_distortion_profile(mode);
    coefficient_param_t coeff = get_coefficient_profile(mode);

    if(distort > 1.0f)
    {
        float delta = distort - 1.0;
        param.distortionParam1 += coeff.c1 * delta;
        param.distortionParam2 += coeff.c2 * delta;
        param.residualMeanError += coeff.c3 * delta;
        param.residualStandardDeviation += coeff.c4 * delta;
        param.m1 += coeff.delta1 * delta;
        param.m2 += coeff.delta2 * delta;
        param.m3 += coeff.delta3 * delta;
        param.m4 += coeff.delta4 * delta;
    }

    glUniform1f(glGetUniformLocation(g_ImageProgram, "fx"), param.focalLengthX);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "fy"), param.focalLengthY);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "cx"), param.centerX);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "cy"), param.centerY);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "k1"), param.distortionParam1);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "k2"), param.distortionParam2);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "p1"), param.residualMeanError);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "p2"), param.residualStandardDeviation);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "distort"), distort);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "m1"), param.m1);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "m2"), param.m2);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "m3"), param.m3);
    glUniform1f(glGetUniformLocation(g_ImageProgram, "m4"), param.m4);

    glUniform1f(glGetUniformLocation(g_ImageProgram, "zoom"), zoomScale);

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void DrawSavedTexture()
{
	glViewport(0, 0, glScreenW, glScreenH);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	glClear(GL_COLOR_BUFFER_BIT);
	glUseProgram(g_DrawProgram);

	float texs[] = { 0, 0, 0, 1, 1, 0, 1, 1};
	float vtCoord[] = { -1, -1, -1, 1, 1, -1, 1, 1};

	glVertexAttribPointer(g_vDrawPositionHandle, 2, GL_FLOAT, GL_FALSE, 0, vtCoord);
	glEnableVertexAttribArray(g_vDrawPositionHandle);
	glVertexAttribPointer(g_vDrawTexPos, 2, GL_FLOAT, GL_FALSE, 0, texs);
	glEnableVertexAttribArray(g_vDrawTexPos);

	glActiveTexture(GL_TEXTURE5);
	glBindTexture(GL_TEXTURE_2D, g_FrameTexture);

	glUniform1i(g_texDrawLoc, 5);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void InitShader()
{
	glClearColor(0, 0, 0, 1);

	g_ImageVertexShader = LoadShader(GL_VERTEX_SHADER, g_VertexShaderStr);
	g_ImageFragmentShader = LoadShader(GL_FRAGMENT_SHADER, g_FragmentShaderStr);
	g_ImageProgram = CreateProgram(g_ImageVertexShader, g_ImageFragmentShader);
	g_vImagePositionHandle = glGetAttribLocation(g_ImageProgram, "vPosition");
	g_vImageTexPos = glGetAttribLocation(g_ImageProgram, "a_texCoord");
	g_texImageLoc = glGetUniformLocation(g_ImageProgram, "effect_tex");

	g_DrawFragmentShader = LoadShader(GL_FRAGMENT_SHADER, g_DrawFragmentShaderStr);
	g_DrawProgram = CreateProgram(g_ImageVertexShader, g_DrawFragmentShader);
	g_vDrawPositionHandle = glGetAttribLocation(g_DrawProgram, "vPosition");
	g_vDrawTexPos = glGetAttribLocation(g_DrawProgram, "a_texCoord");
	g_texDrawLoc = glGetUniformLocation(g_DrawProgram, "effect_tex");
}


void ExitShader()
{
	if(g_nImageWidth != 0 || g_nImageHeight != 0)
		glDeleteTextures(1, &g_ImageTexture);

	if (g_FrameCreated)
	{
		glDeleteTextures(1, &g_FrameTexture);
		glDeleteFramebuffers(1, &g_FrameBuff);
	}

	glDeleteProgram(g_DrawProgram);
	glDeleteShader(g_DrawFragmentShader);

	glDeleteProgram(g_ImageProgram);
	glDeleteShader(g_ImageVertexShader);
	glDeleteShader(g_ImageFragmentShader);
}

int GetGLBpp()
{
	GLint readType, readFormat;
	glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &readType);
	glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &readFormat);
	int bpp = 4;
	if(readType == GL_UNSIGNED_SHORT_5_6_5 && readFormat == GL_RGB)
		bpp = 2;
	else if(readType == GL_UNSIGNED_BYTE && readFormat == GL_RGBA)
		bpp = 4;
	return bpp;
}

void GetGLColorBuffer(char* pGLBuffer, int nGLScreenWidth, int nGLScreenHeight)
{
	GLint readType, readFormat;
	glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_TYPE, &readType);
	glGetIntegerv(GL_IMPLEMENTATION_COLOR_READ_FORMAT, &readFormat);
	glReadPixels(0, 0, nGLScreenWidth, nGLScreenHeight, readFormat, readType, pGLBuffer);
}

