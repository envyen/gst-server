//gst-launch-1.0 v4l2src ! "video/x-raw,width=640,height=480" ! queue ! x264enc ! h264parse ! rtph264pay name=pay0 pt=96 ! queue ! udpsink port=5000 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>

#include <gst/gst.h>
#include <gst/rtsp-server/rtsp-server.h>
#include <glib.h>

#include <gst-server.h>

static void media_configure (GstRTSPMediaFactory *factory, GstRTSPMedia *media)
{
	GstElement *pipeline;
	pipeline = gst_rtsp_media_get_element(media);

	GST_DEBUG_BIN_TO_DOT_FILE(GST_BIN(pipeline), GST_DEBUG_GRAPH_SHOW_ALL, "pipeline");
	printf("Configured\n");

}

int main (int argc, char *argv[])
{
	GMainLoop *loop;
	GstRTSPServer *server;
	GstRTSPMountPoints *mounts;
	GstRTSPMediaFactory *factory;

	gst_init (&argc, &argv);

	loop = g_main_loop_new (NULL, FALSE);

	/* create a server instance */
	server = gst_rtsp_server_new ();

	/* get the mount points for this server, every server has a default object
	 * that be used to map uri mount points to media factories */
	mounts = gst_rtsp_server_get_mount_points (server);

	/* make a media factory for a test stream. The default media factory can use
	 * gst-launch syntax to create pipelines. 
	 * any launch line works as long as it contains elements named pay%d. Each
	 * element with pay%d names will be a stream */
	factory = gst_rtsp_media_factory_new ();
	gst_rtsp_media_factory_set_launch (factory,
			"( udpsrc port=5000 caps=\"application/x-rtp\" ! queue ! rtph264depay ! h264parse ! queue ! rtph264pay name=pay0 pt=96 )");

	gst_rtsp_media_factory_set_shared (factory, TRUE);

	g_signal_connect (factory, "media-configure", (GCallback) media_configure, factory);

	/* attach the test factory to the /test url */
	gst_rtsp_mount_points_add_factory (mounts, "/test", factory);

	/* don't need the ref to the mapper anymore */
	g_object_unref (mounts);

	/* attach the server to the default maincontext */
	gst_rtsp_server_attach (server, NULL);

	/* start serving */
	g_print ("stream ready at rtsp://127.0.0.1:8554/test\n");
	system("sleep 10 && cvlc rtsp://127.0.0.1:8554/test &");
	g_main_loop_run (loop);

	return 0;
}
