use v6.c;

use GLib::Raw::Definitions;

constant ZenityMsgMode is export := guint32;

our enum enum ZenityMsgModeEnum is export <
	ZENITY_MSG_WARNING
	ZENITY_MSG_QUESTION
	ZENITY_MSG_SWITCH
	ZENITY_MSG_ERROR
	ZENITY_MSG_INFO
>;
