# Copyright (c) 2012 by R1cochet <deltaxrho@gmail.com>
# All rights reserved
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

use strict;
use warnings;

my $SCRIPT_NAME = "corrupted_spam";
my $SCRIPT_DESC = "Filter messages in #pre, #tracer and #tracer.spam on Corrupt-Net";

weechat::register($SCRIPT_NAME, "R1cochet", "1.1", "GPL3", $SCRIPT_DESC, "", "");

# initialize global variables
my $config_file;            # config pointer
my %config_section;         # config section pointer
my %config_options_bl;      # init config options
my %config_options_hl;      # init config options

######################### Initial config #########################
sub init_config {
    $config_file = weechat::config_new($SCRIPT_NAME, "config_reload_cb", "");
    return if (!$config_file);

    # create new section in config file
    $config_section{'blacklists'} = weechat::config_new_section($config_file, "blacklists", 0, 0, "", "", "", "", "", "", "", "", "", "");
    if (!$config_section{'blacklists'}) {
        weechat::config_free($config_file);
        return;
    }
    $config_options_bl{'pre.group'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "pre.group", "string",
                                                                       "Comma seperated list of release groups to ignore in #pre. Matches to the end of the release title (release group name)", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'pre.string'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "pre.string", "string",
                                                                       "Comma seperated list of strings to ignore. Matches anywhere in the release title", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'pre.types'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "pre.types", "string",
                                                                       "Comma seperated list of release types to ignore. Exact matches inside the braces [].", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer.group'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer.group", "string",
                                                                       "Comma seperated list of release groups to ignore in #tracer. Matches to the end of the release title (release group name)", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer.string'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer.string", "string",
                                                                       "Comma seperated list of strings to ignore in #tracer. Matches anywhere in the release title", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer.tracker'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer.tracker", "string",
                                                                       "Comma seperated list of trackers to ignore. Exact match inside the braces [].", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer_spam.group'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer_spam.group", "string",
                                                                       "Comma seperated list of groups to ignore in #tracer.spam. Matches to the end of the release title (release group name)", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer_spam.string'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer_spam.string", "string",
                                                                       "Comma seperated list of strings to ignore in #tracer.spam. Matches anywhere in the release title", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_bl{'tracer_spam.tracker'} = weechat::config_new_option($config_file, $config_section{'blacklists'}, "tracer_spam.tracker", "string",
                                                                       "Comma seperated list of trackers to ignore in #tracer.spam. Exact match inside the braces [].", "", 0, 0, "", "", 1, "", "", "", "", "", "",);

    $config_section{'highlights'} = weechat::config_new_section($config_file, "highlights", 0, 0, "", "", "", "", "", "", "", "", "", "");
    if (!$config_section{'highlights'}) {
        weechat::config_free($config_file);
        return;
    }
    $config_options_hl{'pre.string'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "pre.string", "string",
                                                                       "Comma seperated list of strings to highlight in #pre.", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_hl{'pre.types'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "pre.types", "string",
                                                                       "Comma seperated list of release types to highlight in #pre", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_hl{'tracer.string'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "tracer.string", "string",
                                                                       "Comma seperated list of strings to highlight in #tracer.", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_hl{'tracer.tracker'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "tracer.tracker", "string",
                                                                       "Comma seperated list of trackers to highlight in #tracer", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_hl{'tracer_spam.string'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "tracer_spam.string", "string",
                                                                       "Comma seperated list of strings to highlight in #tracer.spam.", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
    $config_options_hl{'tracer_spam.tracker'} = weechat::config_new_option($config_file, $config_section{'highlights'}, "tracer_spam.tracker", "string",
                                                                       "Comma seperated list of trackers to highlight in #tracer.spam.", "", 0, 0, "", "", 1, "", "", "", "", "", "",);
}

# config callbacks
sub config_reload_cb {      # reload config file
    return weechat::config_reload($config_file);
}
sub config_read {           # read my config file
    return weechat::config_read($config_file);
}
sub config_write {          # write to my config file
    return weechat::config_write($config_file);
}

init_config();              # load config
config_read();              # get options if already in config file

# Hook messages
weechat::hook_modifier("weechat_print", "release_info", "");

sub blacklist_type_tracker {        # match type or tracker; front to end
    my ($string, $black_list) = @_;
    my @black_list = split ",", $black_list;
    foreach(@black_list) {
        return 1 if $string =~ /^\Q$_\E\z/; # matches start to end
    }
    return 0;
}

sub blacklist_group {               # match group; end of line
    my ($string, $black_list) = @_;
    my @black_list = split ",", $black_list;
    foreach(@black_list) {
        return 1 if $string =~ /\Q$_\E\z/;  # matches to end only
    }
    return 0;
}

sub blacklist_string {
    my ($string, $black_list) = @_;
    my @black_list = split ",", $black_list;
    foreach(@black_list) {
        return 1 if $string =~ /\Q$_\E/;    # matches anywhere in string
    }
    return 0;
}

sub highlight_string {              # match anywhere in the line
    my ($string, $hilight_list) = @_;
    my @hilight_list = split ",", $hilight_list;
    foreach(@hilight_list) {
        return 1 if $string =~ /\Q$_\E/;    # matches anywhere in string
    }
    return 0;
}

sub highlight_tracker {
    my ($string, $hilight_list) = @_;
    my @hilight_list = split ",", $hilight_list;
    foreach(@hilight_list) {
        return 1 if $string =~ /^\Q$_\E\z/; # matches start to end
    }
    return 0;
}

sub release_info {
    my ($data, $modifier, $modifier_data, $string) = @_;

    #   Parse Modifier Data
    my @mod_data = split(";", $modifier_data);
        # Parse the tags, used for the nick
    return $string if !$mod_data[2];            # return string if there are no tags
    my @tags = split(",", $mod_data[2]);
    return $string if !$tags[3];
        # Check the buffer
    my ($server, $channel) = split(/\./, $mod_data[1], 2);
    return $string if $server !~ /^Corrupt-Net|Corrupt-Net_relay$/i;
    return $string if $channel !~ /^#(pre|tracer|tracer\.spam)$/i;

    #   Parse the message
    my $msg = weechat::string_remove_color($string, "");
    $msg =~ s/\[|\]//g;
    my @msg = split(/\s+/,weechat::string_remove_color($msg, ""));      # Split the message after removing color codes

    if ($channel =~ /^#pre$/i) {
        return $string if $tags[3] !~ /^nick_PR3$/;     # return if nick is not PR3
        return $string if $msg[1] !~ /^PRE:$/i;         # return if msg is not pre:
        # go through blacklists
        if (weechat::config_string($config_options_bl{'pre.group'}) ne "") {
            return "" if blacklist_type_tracker($msg[3], weechat::config_string($config_options_bl{'pre.group'}));
        }
        if (weechat::config_string($config_options_bl{'pre.string'}) ne "") {
            return "" if blacklist_group($msg[3], weechat::config_string($config_options_bl{'pre.string'}));
        }
        if (weechat::config_string($config_options_bl{'pre.types'}) ne "") {
            return "" if blacklist_string($msg[2], weechat::config_string($config_options_bl{'pre.types'}));
        }

        # check for string highlight
        if (weechat::config_string($config_options_hl{'pre.string'}) ne "") {
            if (highlight_string($msg[3], weechat::config_string($config_options_hl{'pre.string'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
        if (weechat::config_string($config_options_hl{'pre.types'}) ne "") {
            if (highlight_tracker($msg[2], weechat::config_string($config_options_hl{'pre.types'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
    }

    if ($channel =~ /^#tracer$/i) {
        return $string if $tags[3] !~ /^nick_TRAC3$/;     # return if nick is not TRAC3
        # go trough the blacklists
        if (weechat::config_string($config_options_bl{'tracer.tracker'}) ne "") {
            return "" if blacklist_type_tracker($msg[2], weechat::config_string($config_options_bl{'tracer.tracker'}));
        }
        if (weechat::config_string($config_options_bl{'tracer.group'}) ne "") {
            return "" if blacklist_group($msg[3], weechat::config_string($config_options_bl{'tracer.group'}));
        }
        if (weechat::config_string($config_options_bl{'tracer.string'}) ne "") {
            return "" if blacklist_string($msg[3], weechat::config_string($config_options_bl{'tracer.string'}));
        }
        # check for string highlight
        if (weechat::config_string($config_options_hl{'tracer.string'}) ne "") {
            if (highlight_string($msg[3], weechat::config_string($config_options_hl{'tracer.string'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
        if (weechat::config_string($config_options_hl{'tracer.tracker'}) ne "") {
            if (highlight_tracker($msg[2], weechat::config_string($config_options_hl{'tracer.tracker'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
    }

    if ($channel =~ /^#tracer\.spam$/i) {
        return $string if $tags[3] !~ /^nick_TRAC3$/;     # return if nick is not TRAC3
        # go trough the blacklists
        if (weechat::config_string($config_options_bl{'tracer_spam.tracker'}) ne "") {
            return "" if blacklist_type_tracker($msg[2], weechat::config_string($config_options_bl{'tracer_spam.tracker'}));
        }
        if (weechat::config_string($config_options_bl{'tracer_spam.group'}) ne "") {
            return "" if blacklist_group($msg[3], weechat::config_string($config_options_bl{'tracer_spam.group'}));
        }
        if (weechat::config_string($config_options_bl{'tracer_spam.string'}) ne "") {
            return "" if blacklist_string($msg[3], weechat::config_string($config_options_bl{'tracer_spam.string'}));
        }
        # check for string highlight
        if (weechat::config_string($config_options_hl{'tracer_spam.string'}) ne "") {
            if (highlight_string($msg[3], weechat::config_string($config_options_hl{'tracer_spam.string'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
        if (weechat::config_string($config_options_hl{'tracer_spam.tracker'}) ne "") {
            if (highlight_tracker($msg[2], weechat::config_string($config_options_hl{'tracer_spam.tracker'}))) {
                my $buffer = weechat::info_get("irc_buffer", "$server,$channel");
                weechat::print_date_tags($buffer, 0, "$tags[0],notify_highlight,$tags[2],$tags[3],$tags[4]", $string);
                return "";
            }
        }
    }

    return $string;
}
