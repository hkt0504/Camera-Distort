#include <stdlib.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include "common.h"

#ifdef __cplusplus
extern "C" {
#endif

	distortion_param_t get_distortion_profile(int mode);
	coefficient_param_t get_coefficient_profile(int mode);

	void	InitShader();
	void	ExitShader();

	
	void	OnFragmentUnifom(char *pSrcBuffer, int nWidth, int nHeight);
	void	OnFragmentDelete();

	GLuint	LoadShader(GLenum type, const char *shaderSrc);
	GLuint	CreateProgram(GLuint vertexShader, GLuint fragmentShader);
	
	void	OnGLESRender(int saveFlag, char *pSrcBuffer, int nWidth, int nHeight);
	void	DrawSavedTexture();

	int 	GetGLBpp();
	void 	GetGLColorBuffer(char* pGLBuffer, int nGLScreenWidth, int nGLScreenHeight);

	extern double 		zoomScale;
	extern double 		distort;
	extern int			mode;
	extern int	 		glScreenW;
	extern int	 		glScreenH;

#ifdef __cplusplus
};
#endif
