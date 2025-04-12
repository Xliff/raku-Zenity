use v6.c;

use Zenity::Raw::Types;

use GTK::Chooser::File::Native:ver<4>;

# cw: Basic operation
#   1) App will call the class, display response and exit
#   2) Class will show dialog and return response for caller

class Zenity::File::Section {
  has $!dialog      is built;
  has $!p;
  has $.exit-code;

  method new (
    :dir(directory(:file_directory(:$file-directory))) = $*PROGRAM.parent,
    :ok(:ok_label(:$ok-label))                         = 'OK',
    :cancel(:cancel_label(:$cancel-label))             = 'Cancel'
    :$modal                                            = False,
    :delay(:timeout_delay(:$timeout-delay)),
    :$uri,
    :$save
 ) {
	GtkFileChooserAction $action = GTK_FILE_CHOOSER_ACTION_OPEN;

  my $action = $save ?? GTK_FILE_CHOOSER_ACTION_SAVE
                     !! GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER;
  
	my $dialog = GTK::Chooser::File::Native.new(
     $dialog_title,
		:$action,
    :$ok-label,
    :$cancel-label
  );

  my $o = self.bless( :$dialog );
  $dialog.modal              = $_ with $modal;
  $dialog.select-multiple    = $_ with $multiple;

  $dialog.Response.tap: SUB { $o.onResponse( |$*A ) }

  if $uri {
  my $s = self;
    my $dg = GLib::GFile.new_for_path( GLib::FileUtils.get_dirname($uri) );
    my $gf = GLib::GFile.new_for_commandline_arg($uri);

    my $le  = gerror;
    my $e  := ppr($le);
    if $uri.ends-with('/') && GLib::FileUtils.is_absolute($uri) {
      $dialog.set_current_folder($dg, $le);
    } else {
      $dialog.set_current_file($gf, $le);
      $dialog.set_current_name( $gf.basename ) if $save && $gf.query_exists.not;
    }

    $*ERR.say( $e.message ) if $e;

    # 	if (file_data->filter)
    # 	{
    # 		/* Filter format: Executables | *.exe *.bat *.com */
    # 		for (int filter_i = 0; file_data->filter[filter_i]; filter_i++)
    # 		{
    # 			GtkFileFilter *filter = gtk_file_filter_new ();
    # 			char *filter_str = file_data->filter[filter_i];
    # 			GStrv pattern;
    # 			g_auto(GStrv) patterns = NULL;
    # 			g_autofree char *name = NULL;
    # 			int i;
    #
    # 			/* Set name */
    # 			for (i = 0; filter_str[i] != '\0'; i++)
    # 				if (filter_str[i] == '|')
    # 					break;
    #
    # 			if (filter_str[i] == '|') {
    # 				name = g_strndup (filter_str, i);
    # 				g_strstrip (name);
    # 			}
    #
    # 			if (name) {
    # 				gtk_file_filter_set_name (filter, name);
    #
    # 				/* Point i to the right position for split */
    # 				for (++i; filter_str[i] == ' '; i++)
    # 					;
    # 			} else {
    # 				gtk_file_filter_set_name (filter, filter_str);
    # 				i = 0;
    # 			}
    #
    # 			/* Get patterns */
    # 			patterns = g_strsplit_set (filter_str + i, " ", -1);
    #
    # 			for (pattern = patterns; *pattern; pattern++)
    # 				gtk_file_filter_add_pattern (filter, *pattern);
    #
    # 			gtk_file_chooser_add_filter (GTK_FILE_CHOOSER(dialog), filter);
    # 		}
    # 	}

    $o;
  }

  method run {
  	$!dialog.show-dialog;
    $dialog.&SETUP-TIMEOUT($_, $!p) with $timeout-delay;
    $!p = Promise.new;
  }

  method onResponse ($, $_, $) {
    $!exit-code = do {
      when GTK_RESPONSE_ACCEPT {
        $!p.keep($.output);
        ZENITY_OK;
      }

      when    GTK_RESPONSE_CANCEL { $!p.break; ZENITY_CANCEL }
      default                     { $!p.break; ZENITY_ESC    }
    }
  }

}

# static void
# zenity_fileselection_dialog_output (GtkFileChooser *chooser,
# 		ZenityFileData *file_data)
# {
# 	g_autoptr(GListModel) model = gtk_file_chooser_get_files (chooser);
# 	guint items = g_list_model_get_n_items (model);
#
# 	for (guint i = 0; i < items; ++i)
# 	{
# 		g_autoptr(GFile) file = g_list_model_get_item (model, i);
#
# 		g_print ("%s", g_file_get_path (file));
#
# 		if (i != items - 1)
# 			g_print ("%s", file_data->separator);
# 	}
# 	g_print ("\n");
# }
#
