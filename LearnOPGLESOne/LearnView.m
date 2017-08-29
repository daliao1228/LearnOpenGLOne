//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/11.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "LearnView.h"
#import <OpenGLES/ES3/gl.h>

@interface LearnView()

@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLuint shaderProgram2;

- (void)setupLayer;

@end

@implementation LearnView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)dealloc {
    [self destoryRenderAndFrameBuffer];
}

- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self testRenderBufferTwoShaders];
}

- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)render {
    glClearColor(0.0, 0.0, 0.0, 1.0); // 设置环境颜色，既整个画布是什么颜色
    glClear(GL_COLOR_BUFFER_BIT); // 使用刚才设置的啥颜色
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    self.shaderProgram = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"]
                                   fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"]]; // 编译Shader
    
    glLinkProgram(self.shaderProgram); // 链接ShaderPragrom
    glUseProgram(self.shaderProgram); // 使用ShaderPragrom
    
    
    GLfloat attrArr[] =
    {
        -0.5f, -0.5f, 0.0f,
         0.5f, -0.5f, 0.0f,
         0.0f,  0.5f, 0.0f
    }; // 需要输入的顶点坐标，范围(-1.0, 1.0)，分别为x, y, z
    
    GLuint attrBuffer; //声明一个VBO（Vertex Buffer Object），vertex指的是顶点
    glGenBuffers(1, &attrBuffer); // 生成attrBuffer
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer); // 将顶点绑定到GL_ARRAY_BUFFER，Buffer都是glGen+glBind+glBufferData
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW); // 将我们刚才定义的顶点赋值给GL_ARRAY_BUFFER，既将我们刚才定一的点上传到GPU，后面再有的地方使用GL_ARRAY_BUFFER，既使用我们定义的顶点
    
    GLuint position = glGetAttribLocation(self.shaderProgram, "position"); // 这里有一点不一向的地方，我们直接取出了shader里面的参数position，就是shader定义的attribute
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL); // 将我们刚才给的顶点坐标给到shader里面的position属性，这里几个参数更加详细的解读一下
                                                                                       // 1.indx,指的是我们要将顶点绑定给谁，比如我们致力传入position，就是刚才我们从Shader里拿的参数
                                                                                       // 第二个参数指定顶点属性的大小。顶点属性是一个vec3，它由3个值组成，所以大小是3
                                                                                       // 第三个参数指定数据的类型，这里是GL_FLOAT(GLSL中vec*都是由浮点数值组成的)
                                                                                       // * 下个参数定义我们是否希望数据被标准化(Normalize)。如果我们设置为GL_TRUE，所有数据都会被映射到0（对于有符号型signed数据是-1）到1之间。我们把它设置为GL_FALSE。
                                                                                       //* 第五个参数叫做步长(Stride)，它告诉我们在连续的顶点属性组之间的间隔。由于下个组位置数据在3个float之后，我们把步长设置为3 * sizeof(float)。要注意的是由于我们知道这个数组是紧密排列的（在两个顶点属性之间没有空隙）我们也可以设置为0来让OpenGL决定具体步长是多少（只有当数值是紧密排列时才可用）。一旦我们有更多的顶点属性，我们就必须更小心地定义每个顶点属性之间的间隔，我们在后面会看到更多的例子（译注: 这个参数的意思简单说就是从这个属性第二次出现的地方到整个数组0位置之间有多少字节）。
    
    
    glEnableVertexAttribArray(position);
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)EBORender {
    glClearColor(0.0, 0.0, 0.0, 1.0); // 设置环境颜色，既整个画布是什么颜色
    glClear(GL_COLOR_BUFFER_BIT); // 使用刚才设置的啥颜色
    
    CGFloat scale = [[UIScreen mainScreen] scale]; //获取视图放大倍数，可以把scale设置为1试试
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    self.shaderProgram = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"]
                                 fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"]]; // 编译Shader
    
    glLinkProgram(self.shaderProgram);
    glUseProgram(self.shaderProgram);
    
    
    GLfloat attrArr[] =
    {
        0.5f, 0.5f, 0.0f,   // 右上角
        0.5f, -0.5f, 0.0f,  // 右下角
        -0.5f, -0.5f, 0.0f, // 左下角
        -0.5f, 0.5f, 0.0f   // 左上角
    };
    
    unsigned int indeice[] = { // 这里面是指几个点，0指的是第一排，3指的是最后一排
        0, 1, 3,
        1, 2, 3
    };
    
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    GLuint EBO;
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indeice), indeice, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.shaderProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    
    
    glEnableVertexAttribArray(position);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0); // 第一个参数指定了我们绘制的模式，这个和glDrawArrays的一样。第二个参数是我们打算绘制顶点的个数，这里填6，也就是说我们一共需要绘制6个顶点。第三个参数是索引的类型，这里是GL_UNSIGNED_INT。最后一个参数里我们可以指定EBO中的偏移量（或者传递一个索引数组，但是这是当你不在使用索引缓冲对象的时候），但是我们会在这里填写0。
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)testRenderTwoTringles {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    self.shaderProgram = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"]
                                 fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"]]; // 编译Shader
    
    glLinkProgram(self.shaderProgram);
    glUseProgram(self.shaderProgram);
    
    
    GLfloat attrArr[] =
    {
        -0.5f,  0.0f, 0.0f,
         0.5f,  0.0f, 0.0f,
         0.0f,  0.5f, 0.0f,
         0.0f, -0.5f, 0.0f
    };
    
    unsigned int indexs[] =
    {
        0, 1, 2,
        0, 1, 3
    };
    
    GLuint attrBuffer, EBO;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexs), indexs, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.shaderProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    glEnableVertexAttribArray(position);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)testRenderBufferTwoShaders {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale); //设置视口大小
    
    self.shaderProgram = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"]
                                   fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"]]; // 编译Shader
    
    self.shaderProgram2 = [self loadVertexShaders:[[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"]
                                    fragmentShaders:[[NSBundle mainBundle] pathForResource:@"shaderf2" ofType:@"fsh"]];
    
    glLinkProgram(self.shaderProgram);
    glLinkProgram(self.shaderProgram2);

    GLfloat attrArr[] =
    {
        -0.5f,  0.0f, 0.0f,
         0.5f,  0.0f, 0.0f,
         0.0f,  0.5f, 0.0f,
         0.0f, -0.5f, 0.0f
    };
    
    unsigned int indexs[] =
    {
        0, 1, 2,
    };
    
    unsigned int indexs2[] =
    {
        0, 1, 3
    };
    
    GLuint attrBuffer, EBO;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &EBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexs), indexs, GL_DYNAMIC_DRAW);
    
    GLuint position = glGetAttribLocation(self.shaderProgram, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    glEnableVertexAttribArray(position);
    
    glUseProgram(self.shaderProgram);
    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);
    
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexs2), indexs2, GL_DYNAMIC_DRAW);
    glUseProgram(self.shaderProgram2);
    glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (GLuint)loadVertexShaders:(NSString *)vertexShaderPath fragmentShaders:(NSString *)fragmentShaderPath {
    
    GLuint shaderProgram = glCreateProgram();
    
    GLuint vertexShader = [self compileShaderWithFilePath:vertexShaderPath shaderType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithFilePath:fragmentShaderPath shaderType:GL_FRAGMENT_SHADER];
    
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return shaderProgram;
}

- (GLuint)compileShaderWithFilePath:(NSString *)filePath shaderType:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const GLchar *source = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (source == NULL) {
        NSLog(@"shader file is not exist");
        return 0;
    }
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[512];
        glGetShaderInfoLog(shader, 512, NULL, messages);
        NSString *errorMessage = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", errorMessage);
    }
    return shader;
}

- (void)checkGLError {
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        NSLog(@"GL error: 0x%x", glError);
    }
}

@end
