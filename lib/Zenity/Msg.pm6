use v6.c;

use Zenity::Raw::Types;

use GTK::Settings:ver<4>;
use Zenity::Util;

class Zenity::Msg {
  has $!dialog        is built;
  has $!timeout-delay is built;
  has $!b             is built handles(*);
  has $!p;
  has @!extras;
  has $.exit-code;

  method builder {
    $!b;
  }

  method new {
    :title(:dialog_title(:$dialog-title))          = 'Message',
	  :ok(:ok_label(:$ok-label))                     = 'OK',
	  :cancel(:cancel_label(:$cancel-label))         = 'Cancel',
    :w(:$width)                                    = 640,
    :h(:$height)                                   = 480,
    :$modal                                        = False,
    :no_wrap(:$no-wrap)                            = False,
    :no_markup(:$no-markup)                        = False
    :default_cancel(:default-cancel)               = False
    :dots(:$ellipsize)                             = False
    :$info                                         = True,
    :$mode                                is copy,
    :$error,
    :$question,
    :$warning,
    :$switch,
    :exit_code(:$exit-code);
    :delay(:timeout_delay(:$timeout-delay)),
	  :extras(:extra_labels(:@extra-labels),
    :text(:dialog_text(:$dialog-text)),
	  :icon(:dialog_icon(:$dialog-icon))
  ) {
    without $mode {
      $mode = do {
        when    $error.so     { ZENITY_MSG_ERROR    }
        when    $question.so  { ZENITY_MSG_WARNING  }
        when    $warning.so   { ZENITY_MSG_QUESTION }
        when    $switch.so    { ZENITY_MSG_SWITCH   }
        when    $info.so      { ZENITY_MSG_INFO     }
        default               { $mode               }
      }
    }

    X::Zenity::InvalidMsgMode.new.throw
      unless $mode == ZenityMessageModeEnum.pairs.values.any;d

    my $b;
    my $mn = $mode.Str.split('_').tail.lc;

    $b = Zenity::Util.load_ui_file(
      "zenity_{ $mn }_dialog",
      "zenity_{ $mn }_box"
    );

    X::Zenity::InvalidBuilder.new.throw unless $b;

    my ($dialog, $text, $image) = $b«
      "zenity_{ $mn }_dialog"
      "zenity_{ $mn }_text"
      "zenity_{ $mn }_image"
    »;

    my $o = self.bless( :$dialog, :$b, :$timeout-delay );

    $image.set_from_gicon($_)
      with Zenity::Util.gicon_from_string($dialog-icon);

    if $mode == ZENITY_MSG_QUESTION {
      $dialog.add_responses(
        'no',  'No',
        'yes', 'Yes'
      );
      $dialog.default-response = $default-cancel ?? 'no' !! 'yes';
    }

    $dialog.Response.tap: SUB { $o.onResponse( $*A ) }

    $dialog.setAttributes(
      default-size => ($width, $height),
      modal        => $modal
      icon-name    => "dialog-{ $mn }"
    );

    $text.setAttributes(
       size-request => ($width, -1),
       ellipsize    =>  $ellipsize,
       no-wrap      =>  $no-wrap,
      (text         =>  $dialog-text if $dialog-text && $no-markup),
      (markup       =>  $dialog-text if $dialog-text && $no-markup.not)
    );

    $dialog.&ADD-EXTRA-LABELS($_)          with @extra-labels;
    $dialog.&SETUP-OK-BUTTON-LABEL($_)     with $ok-label;
    $dialog.&SETUP-CANCEL-BUTTON-LABEL($_) with $cancel-label;

    Zenity::Util.setup_dialog_title($dialog, $dialog-title);

    GTK::Settings.default.gtk-label-select-on-focus = False;
  }

  method run {
    $!dialog.show-dialog;
    $!dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

  method onResponse ($, $_, $) {
    $!exit-code = do {
      when ZENITY_OK      { $!p.keep( $.output ); $_ }
      when ZENITY_TIMEOUT { $!p.keep( $.output ); $_ }
      when ZENITY_CANCEL  { $!p.break;            $_ }
      when ZENITY_ESC     { $!p.break;            $_ }

      default             { HANDLE_EXTRA_BUTTONS($_) }
    }
  }

}
