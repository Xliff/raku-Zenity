use v6.c;

use Zenity::Raw::Types;

use GTK::Chooser::Color::Dialog;

use GTK::Raw::Chooser::Color::Dialog:ver<4>;

class Zenity::Color {
  has $!dialog        is built;
  has $!timeout-delay is built;
  has $!p;
  has @!extras;
  has $.exit-code;

  method new (
    :title(:dialog_title(:$dialog-title))   = 'Color',
    :ok(:ok_label(:$ok-label))              = 'OK',
    :cancel(:cancel_label(:$cancel-label))  = 'Cancel',
    :$modal                                 = False,
    :palette(:show_palette($show-palette))  = False,
    :$color                                 = '#ffffff',
    :delay(:timeout_delay(:$timeout-delay))
  ) {
    my $dialog = GTK::Chooser::Color::Dialog.new($dialog-title);
    $dialog.modal       = $_                           given $modal
    $dialog.show-editor = .not                         given $show-palette;

    $dialog.set_custom_button(GTK_RESPONSE_OK, $_)     with $ok-label;
    $dialog.set_custom_button(GTK_RESPONSE_CANCEL, $_) with $cancel-label;
    $dialog.&ADD-EXTRA-LABELS($_)                      with @extra-labels;

    my $o = self.bless( :$dialog, :$timeout-delay );

    $dialog.Response.tap: SUB { $o.onResponse( |$*A ) }

    $o;
  }

  method set_custom_button($r, $l) {
    @!extras.push: Pair.new($r, $l);
    nextsame;
  }

  method onResponse ($, $_, $) {
    $!exit-code = do {
      when GTK_RESPONSE_OK {
  			$!p.keep( $!dialog.get_rgba );
        ZENITY_OK;
      }

		  when     GTK_RESPONSE_CANCEL       { $!p.break; ZENITY_CANCEL           }
		  when     GTK_RESPONSE_DELETE_EVENT { $!p.break; ZENITY_ESC              }
		  default                            { HANDLE_EXTRA_BUTTONS($_, @!extras) }
    }
	}

  method run {
  	$!dialog.show-dialog;
    $dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

}
