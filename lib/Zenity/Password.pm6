use v6.c;

use Zenity::Raw::Types;

use Zenity::Util;

class Zenity::Password {
  has $!dialog         is built;
  has $!timeout-delay  is built;
  has $!username-entry is built;
  has $!password-entry is built;
  has $!b              is built  handles(*);

  has $!p;
  has @!extras;
  has $.exit-code;

  method builder {
    $!b;
  }

  method new {
    :title(:dialog_title(:$dialog-title))             = 'Password',
    :ok(:ok_label(:$ok-label))                        = 'OK',
    :cancel(:cancel_label(:$cancel-label))            = 'Cancel',
    :w(:$width)                                       = 640,
    :h(:$height)                                      = 480,
    :$modal                                           = False,
    :user(:username(:show_username(:$show-username))) = True,
    :exit_code(:$exit-code);
    :delay(:timeout_delay(:$timeout-delay)),
    :extras(:extra_labels(:@extra-labels),
    :text(:dialog_text(:$dialog-text)),
    :icon(:dialog_icon(:$dialog-icon)),
	  :$password
  ) {
    my $b = Zenity::Util.load_ui_file(
      <
        zenity_password_dialog
        zenity_password_box
      >
    );

    X::Zenity::InvalidBuilder.new.throw unless $b;

    my ($dialog, $grid) = $b<
      zenity_password_dialog
      zenity_password_grid
    >;

    $dialog.&ADD-EXTRA-LABELS($_)          with @extra-labels;
    $dialog.&SETUP-OK-BUTTON-LABEL($_)     with $ok-label;
    $dialog.&SETUP-CANCEL-BUTTON-LABEL($_) with $cancel-label;
    Zenity::Util.setup_dialog_title($dialog, $dialog-title);

    $dialog.modal = $modal;

    my ($row, $username-entry) = 0;
    if $show-username {
      %b<zenity_password_title>.text = 'Type your username and password';

      my $label = GTK::Label.new('Username:');
      $grid.attach($label, 0, 0);

      $username-entry = GTK::Entry.new;
      $grid.attach($username-entry, 1, 0);
      ++$row;
    }

    my $label = GTK::Label.new('Password:');
    $grid.attach($label, $row, 0);

    my $password-entry = GTK::Entry.new;
    $grid.attach($password-entry, $row, 1);
    ++$row;

    $password-entry.setAttributes(
      visibility        => False,
      input-purpose     => GTK_INPUT_PURPOS_PASSWORD,
      activates-default => True
    );

    my $o = self.bless(
      :$dialog,
      :$b,
      :$timeout-delay,
      :$password-entry,

      (username-entry => $_ with $username-entry)
    );

    $dialog.Response.tap: SUB { $o.onResponse( $*A ) }

    $o;
  }

  method run {
    $!dialog.show-dialog;
    $!dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

  method onResponse ($, $_, $) {
    my $r = {
      Username => $!username-entry.text,
      Password => $!password-entry.text
    }

    $!exit-code = do {
      when ZENITY_OK      { $!p.keep($r);  $_ }
      when ZENITY_TIMEOUT { $!p.keep;      $_ }
      when ZENITY_CANCEL  { $!p.break;     $_ }
      when ZENITY_ESC     { $!p.break;     $_ }

      default             { HANDLE_EXTRA_BUTTONS($_) }
    }
  }

}
