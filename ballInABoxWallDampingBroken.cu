//nvcc ballInABoxFixed.cu -o bounce -lglut -lm -lGLU -lGL																													
//To stop hit "control c" in the window you launched it from.
#include <iostream>
#include <fstream>
#include <sstream>
#include <string.h>
#include <GL/glut.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <cuda.h>
#include <curand.h>
#include <curand_kernel.h>
using namespace std;

float TotalRunTime;
float RunTime;
float Dt;
float4 Position, Velocity, Force;
float SphereMass;
float SphereDiameter;
float BoxSideLength;
float damping=0.90;//how much kinetic energy is retained after each collision 
const float gravity = -9.81;//gravity 


// Window globals
static int Window;
int XWindowSize;
int YWindowSize;
double Near;
double Far;
double EyeX;
double EyeY;
double EyeZ;
double CenterX;
double CenterY;
double CenterZ;
double UpX;
double UpY;
double UpZ;

void setInitailConditions();
void drawPicture();
void getForces();
void updatePositions();
void nBody();
void startMeUp();

void Display()
{
	drawPicture();
}

void idle()
{
	nBody();
}

void reshape(int w, int h)
{
	glViewport(0, 0, (GLsizei) w, (GLsizei) h);
}

void setInitailConditions()
{
	SphereDiameter = 0.5;
	SphereMass = 1.0;
	BoxSideLength = 5.0;
	
	Position.x = 0.0;
	Position.y = 0.0;
	Position.z = 0.0;
	
	Velocity.x = 11.0;
	Velocity.y = 11.0;
	Velocity.z = 15.0;
	
	Force.x = 0.0;
	Force.y = 0.0;
	Force.z = 0.0;
	
	TotalRunTime = 10000.0;
	RunTime = 0.0;
	Dt = 0.005;
}

void drawPicture()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glClear(GL_DEPTH_BUFFER_BIT);
	
	float halfSide = BoxSideLength/2.0;
	
	glColor3d(2.0, 0.5, 1.0);
	glPushMatrix();
		glTranslatef(Position.x, Position.y, Position.z);
		glutSolidSphere(SphereDiameter/2.0, 30, 30);
	glPopMatrix();
	
	glLineWidth(3.0);
	//Drawing front of box
	glColor3d(0.0, 1.0, 0.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
	glEnd();
	//Drawing back of box
	glColor3d(1.0, 1.0, 1.0);
	glBegin(GL_LINE_LOOP);
		glVertex3f(-halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off right side
	glBegin(GL_LINES);
		glVertex3f(halfSide, halfSide, halfSide);
		glVertex3f(halfSide, halfSide, -halfSide);
		glVertex3f(halfSide, -halfSide, halfSide);
		glVertex3f(halfSide, -halfSide, -halfSide);
	glEnd();
	// Finishing off left side
	glBegin(GL_LINES);
		glVertex3f(-halfSide, halfSide, halfSide);
		glVertex3f(-halfSide, halfSide, -halfSide);
		glVertex3f(-halfSide, -halfSide, halfSide);
		glVertex3f(-halfSide, -halfSide, -halfSide);
	glEnd();
	
	
	glutSwapBuffers();
}

void getForces()
{
	float wallStiffness = 10000.0;
	float halfSide = BoxSideLength/2.0;
	float howMuch;
	float ballRadius = SphereDiameter/2.0;

	
	Force.x = 0.0;
	Force.y = gravity*SphereMass;//gravatational force.F=M*A
	Force.z = 0.0;
	
	if((Position.x - ballRadius) < -halfSide)
	{
		howMuch = -halfSide - (Position.x - ballRadius);
		Force.x += wallStiffness*howMuch;
		Velocity.x *=damping;//loss of energy from heat results in loss of velocity 
		
	}
	else if(halfSide < (Position.x + ballRadius))
	{
		howMuch = (Position.x + ballRadius) - halfSide;
		Force.x -= wallStiffness*howMuch;
		Velocity.x *=damping;
	}
	
	if((Position.y - ballRadius) < -halfSide)
	{
		howMuch = -halfSide - (Position.y - ballRadius);
		Force.y += wallStiffness*howMuch;
		Velocity.y *=damping;

	}
	else if(halfSide < (Position.y + ballRadius))
	{
		howMuch = (Position.y + ballRadius) - halfSide;
		Force.y -= wallStiffness*howMuch;
		Velocity.y *=damping;
	}
	
	if((Position.z - ballRadius) < -halfSide)
	{
		howMuch = -halfSide - (Position.z - ballRadius);
		Force.z += wallStiffness*howMuch;
		Velocity.z *=damping;

	}
	else if(halfSide < (Position.z + ballRadius))
	{
		howMuch = (Position.z + ballRadius) - halfSide;
		Force.z -= wallStiffness*howMuch;
		Velocity.z *=damping;
	}
}

void updatePositions()
{

	// These are the LeapFrog formulas.
	if(RunTime == 0.0)
	{
		Velocity.x += (Force.x/SphereMass)*(Dt/2.0);
		Velocity.y += (Force.y/SphereMass)*(Dt/2.0);
		Velocity.z += (Force.z/SphereMass)*(Dt/2.0);
	}
	else
	{
		Velocity.x += ((Force.x/SphereMass)*Dt);
		Velocity.y += (Force.y/SphereMass)*Dt;
		Velocity.z += (Force.z/SphereMass)*Dt;
	
	}
	

	
printf("\nvelocity in the x %f",Velocity.x);
printf("\nvelocity in the y %f",Velocity.y);
printf("\nvelocity in the z %f",Velocity.z);


	Position.x += Velocity.x*Dt;
	Position.y += Velocity.y*Dt;
	Position.z += Velocity.z*Dt;
}

void nBody()
{	
	getForces();
	updatePositions();
	drawPicture();
	printf("\n Time = %f", RunTime);
	RunTime += Dt;
	
	if(TotalRunTime < RunTime)
	{
		glutDestroyWindow(Window);
		printf("\n Later Dude \n");
		exit(0);
	}
}

void startMeUp() 
{	
	// The Rolling Stones
	// Tattoo You: 1981
	setInitailConditions();
}

int main(int argc, char** argv)
{
	startMeUp();
	
	XWindowSize = 1000;
	YWindowSize = 1000; 

	// Clip plains
	Near = 0.2;
	//Far = BoxSideLength;
	Far = 10.0;

	//Where your eye is located
	EyeX = 0.0;
	EyeY = 0.0;
	EyeZ = 6.0;

	//Where you are looking
	CenterX = 0.0;
	CenterY = 0.0;
	CenterZ = 0.0;

	//Up vector for viewing
	UpX = 0.0;
	UpY = 1.0;
	UpZ = 0.0;
	
	glutInit(&argc,argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_DEPTH | GLUT_RGB);
	glutInitWindowSize(XWindowSize,YWindowSize);
	glutInitWindowPosition(5,5);
	Window = glutCreateWindow("Particle In A Box");
	
	gluLookAt(EyeX, EyeY, EyeZ, CenterX, CenterY, CenterZ, UpX, UpY, UpZ);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-0.2, 0.2, -0.2, 0.2, Near, Far);
	glMatrixMode(GL_MODELVIEW);
	
	glClearColor(0.0, 0.0, 0.0, 0.0);
		
	GLfloat light_position[] = {1.0, 1.0, 1.0, 0.0};
	GLfloat light_ambient[]  = {0.0, 0.0, 0.0, 1.0};
	GLfloat light_diffuse[]  = {1.0, 1.0, 1.0, 1.0};
	GLfloat light_specular[] = {1.0, 1.0, 1.0, 1.0};
	GLfloat lmodel_ambient[] = {0.2, 0.2, 0.2, 1.0};
	GLfloat mat_specular[]   = {1.0, 1.0, 1.0, 1.0};
	GLfloat mat_shininess[]  = {10.0};
	glShadeModel(GL_SMOOTH);
	glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
	glLightfv(GL_LIGHT0, GL_POSITION, light_position);
	glLightfv(GL_LIGHT0, GL_AMBIENT, light_ambient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, light_diffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, light_specular);
	glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
	glMaterialfv(GL_FRONT, GL_SPECULAR, mat_specular);
	glMaterialfv(GL_FRONT, GL_SHININESS, mat_shininess);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glEnable(GL_COLOR_MATERIAL);
	glEnable(GL_DEPTH_TEST);
	
	glutDisplayFunc(Display);
	glutReshapeFunc(reshape);
	//glutMouseFunc(mymouse);
	//glutKeyboardFunc(KeyPressed);
	glutIdleFunc(idle);
	glutMainLoop();
	
	return 0;
}
