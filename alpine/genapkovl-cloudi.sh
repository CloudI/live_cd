#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
cloudi
nodejs
perl
php7
python3
ruby
EOF

makefile root:root 0644 "$tmp"/etc/motd <<EOF
CloudI 1.8.0 LiveCD!

    To run the integration tests use:
        service cloudi stop
        cp /etc/cloudi/cloudi_tests.conf /etc/cloudi/cloudi.conf
        service cloudi start

    To avoid extra RAM consumption the programming language packages
    listed below are not installed by default:
        go             (Go support)
        openjdk8       (Java support)
        ghc cabal      (Haskell support (x86_64 only))
        ocaml          (OCaml suppoort (x86_64 only))

    The LiveCD filesystem only has enough space for one of the
    programming languages listed above, with the installation as:
        apk add openjdk8

EOF

mkdir -p "$tmp"/etc/conf.d/
makefile root:root 0644 "$tmp"/etc/conf.d/ntpd <<EOF
NTPD_OPTS="-N -p pool.ntp.org"
EOF
makefile root:root 0644 "$tmp"/etc/rc.conf <<EOF
# Global OpenRC configuration settings

# Set to "YES" if you want the rc system to try and start services
# in parallel for a slight speed improvement. When running in parallel we
# prefix the service output with its name as the output will get
# jumbled up.
# WARNING: whilst we have improved parallel, it can still potentially lock
# the boot process. Don't file bugs about this unless you can supply
# patches that fix it without breaking other things!
#rc_parallel="NO"

# Set rc_interactive to "YES" and you'll be able to press the I key during
# boot so you can choose to start specific services. Set to "NO" to disable
# this feature. This feature is automatically disabled if rc_parallel is
# set to YES.
#rc_interactive="YES"

# If we need to drop to a shell, you can specify it here.
# If not specified we use $SHELL, otherwise the one specified in /etc/passwd,
# otherwise /bin/sh
# Linux users could specify /sbin/sulogin
#rc_shell=/bin/sh

# Do we allow any started service in the runlevel to satisfy the dependency
# or do we want all of them regardless of state? For example, if net.eth0
# and net.eth1 are in the default runlevel then with rc_depend_strict="NO"
# both will be started, but services that depend on 'net' will work if either
# one comes up. With rc_depend_strict="YES" we would require them both to
# come up.
#rc_depend_strict="YES"

# rc_hotplug controls which services we allow to be hotplugged.
# A hotplugged service is one started by a dynamic dev manager when a matching
# hardware device is found.
# Hotplugged services appear in the "hotplugged" runlevel.
# If rc_hotplug is set to any value, we compare the name of this service
# to every pattern in the value, from left to right, and we allow the
# service to be hotplugged if it matches a pattern, or if it matches no
# patterns. Patterns can include shell wildcards.
# To disable services from being hotplugged, prefix patterns with "!".
#If rc_hotplug is not set or is empty, all hotplugging is disabled.
# Example - rc_hotplug="net.wlan !net.*"
# This allows net.wlan and any service not matching net.* to be hotplugged.
# Example - rc_hotplug="!net.*"
# This allows services that do not match "net.*" to be hotplugged.

# rc_logger launches a logging daemon to log the entire rc process to
# /var/log/rc.log
# NOTE: Linux systems require the devfs service to be started before
# logging can take place and as such cannot log the sysinit runlevel.
#rc_logger="NO"

# Through rc_log_path you can specify a custom log file.
# The default value is: /var/log/rc.log
#rc_log_path="/var/log/rc.log"

# If you want verbose output for OpenRC, set this to yes. If you want
# verbose output for service foo only, set it to yes in /etc/conf.d/foo.
#rc_verbose=no

# By default we filter the environment for our running scripts. To allow other
# variables through, add them here. Use a * to allow all variables through.
#rc_env_allow="VAR1 VAR2"

# By default we assume that all daemons will start correctly.
# However, some do not - a classic example is that they fork and return 0 AND
# then child barfs on a configuration error. Or the daemon has a bug and the
# child crashes. You can set the number of milliseconds start-stop-daemon
# waits to check that the daemon is still running after starting here.
# The default is 0 - no checking.
#rc_start_wait=100

# rc_nostop is a list of services which will not stop when changing runlevels.
# This still allows the service itself to be stopped when called directly.
#rc_nostop=""

# rc will attempt to start crashed services by default.
# However, it will not stop them by default as that could bring down other
# critical services.
#rc_crashed_stop=NO
#rc_crashed_start=YES

# Set rc_nocolor to yes if you do not want colors displayed in OpenRC
# output.
#rc_nocolor=NO

##############################################################################
# MISC CONFIGURATION VARIABLES
# There variables are shared between many init scripts

# Set unicode to YES to turn on unicode support for keyboards and screens.
#unicode="NO"

# This is how long fuser should wait for a remote server to respond. The
# default is 60 seconds, but  it can be adjusted here.
#rc_fuser_timeout=60

# Below is the default list of network fstypes.
#
# afs ceph cifs coda davfs fuse fuse.sshfs gfs glusterfs lustre ncpfs
# nfs nfs4 ocfs2 shfs smbfs
#
# If you would like to add to this list, you can do so by adding your
# own fstypes to the following variable.
#extra_net_fs_list=""

##############################################################################
# SERVICE CONFIGURATION VARIABLES
# These variables are documented here, but should be configured in
# /etc/conf.d/foo for service foo and NOT enabled here unless you
# really want them to work on a global basis.
# If your service has characters in its name which are not legal in
# shell variable names and you configure the variables for it in this
# file, those characters should be replaced with underscores in the
# variable names as shown below.

# Some daemons are started and stopped via start-stop-daemon.
# We can set some things on a per service basis, like the nicelevel.
#SSD_NICELEVEL="-19"
# Or the ionice level. The format is class[:data] , just like the
# --ionice start-stop-daemon parameter.
#SSD_IONICELEVEL="2:2"

# Pass ulimit parameters
# If you are using bash in POSIX mode for your shell, note that the
# ulimit command uses a block size of 512 bytes for the -c and -f
# options
rc_ulimit="-n 65535 -c unlimited"
#rc_ulimit="-u 30"

# It's possible to define extra dependencies for services like so
#rc_config="/etc/foo"
#rc_need="openvpn"
#rc_use="net.eth0"
#rc_after="clock"
#rc_before="local"
#rc_provide="!net"

# You can also enable the above commands here for each service. Below is an
# example for service foo.
#rc_foo_config="/etc/foo"
#rc_foo_need="openvpn"
#rc_foo_after="clock"

# Below is an example for service foo-bar. Note that the '-' is illegal
# in a shell variable name, so we convert it to an underscore.
# example for service foo-bar.
#rc_foo_bar_config="/etc/foo-bar"
#rc_foo_bar_need="openvpn"
#rc_foo_bar_after="clock"

# You can also remove dependencies.
# This is mainly used for saying which services do NOT provide net.
#rc_net_tap0_provide="!net"

# This is the subsystem type.
# It is used to match against keywords set by the keyword call in the
# depend function of service scripts.
#
# It should be set to the value representing the environment this file is
# PRESENTLY in, not the virtualization the environment is capable of.
# If it is commented out, automatic detection will be used.
#
# The list below shows all possible settings as well as the host
# operating systems where they can be used and autodetected.
#
# ""               - nothing special
# "docker"         - Docker container manager (Linux)
# "jail"           - Jail (DragonflyBSD or FreeBSD)
# "lxc"            - Linux Containers
# "openvz"         - Linux OpenVZ
# "prefix"         - Prefix
# "rkt"            - CoreOS container management system (Linux)
# "subhurd"        - Hurd subhurds (to be checked)
# "systemd-nspawn" - Container created by systemd-nspawn (Linux)
# "uml"            - Usermode Linux
# "vserver"        - Linux vserver
# "xen0"           - Xen0 Domain (Linux and NetBSD)
# "xenU"           - XenU Domain (Linux and NetBSD)
#rc_sys=""

# if  you use openrc-init, which is currently only available on Linux,
# this is the default runlevel to activate after "sysinit" and "boot"
# when booting.
#rc_default_runlevel="default"

# on Linux and Hurd, this is the number of ttys allocated for logins
# It is used in the consolefont, keymaps, numlock and termencoding
# service scripts.
rc_tty_number=12

##############################################################################
# LINUX CGROUPS RESOURCE MANAGEMENT

# This sets the mode used to mount cgroups.
# "hybrid" mounts cgroups version 2 on /sys/fs/cgroup/unified and
# cgroups version 1 on /sys/fs/cgroup.
# "legacy" mounts cgroups version 1 on /sys/fs/cgroup
# "unified" mounts cgroups version 2 on /sys/fs/cgroup
#rc_cgroup_mode="hybrid"

# This is a list of controllers which should be enabled for cgroups version 2.
# If hybrid mode is being used, controllers listed here will not be
# available for cgroups version 1.
# This is a global setting.
#rc_cgroup_controllers=""

# This variable contains the cgroups version 2 settings for your services.
# If this is set in this file, the settings will apply to all services.
# If you want different settings for each service, place the settings in
# /etc/conf.d/foo for service foo.
# The format is to specify the setting and value followed by a newline.
# Multiple settings and values can be specified.
# For example, you would use this to set the maximum memory and maximum
# number of pids for a service.
#rc_cgroup_settings="
#memory.max 10485760
#pids.max max
#"
#
# For more information about the adjustments that can be made with
# cgroups version 2, see Documentation/cgroups-v2.txt in the linux kernel
# source tree.
#rc_cgroup_settings=""

# This switch controls whether or not cgroups version 1 controllers are
# individually mounted under
# /sys/fs/cgroup in hybrid or legacy mode.
#rc_controller_cgroups="YES"

# The following setting turns on the memory.use_hierarchy setting in the
# root memory cgroup for cgroups v1.
# It must be set to yes in this file if you want this functionality.
#rc_cgroup_memory_use_hierarchy="NO"

# The following settings allow you to set up values for the cgroups version 1
# controllers for your services.
# They can be set in this file;, however, if you do this, the settings
# will apply to all of your services.
# If you want different settings for each service, place the settings in
# /etc/conf.d/foo for service foo.
# The format is to specify the names of the settings followed by their
# values. Each variable can hold multiple settings.
# For example, you would use this to set the cpu.shares setting in the
# cpu controller to 512 for your service.
# rc_cgroup_cpu="
# cpu.shares 512
# "
#
# For more information about the adjustments that can be made with
# cgroups version 1, see Documentation/cgroups-v1/* in the linux kernel
# source tree.

# Set the blkio controller settings for this service.
#rc_cgroup_blkio=""

# Set the cpu controller settings for this service.
#rc_cgroup_cpu=""

# Add this service to the cpuacct controller (any value means yes).
#rc_cgroup_cpuacct=""

# Set the cpuset controller settings for this service.
#rc_cgroup_cpuset=""

# Set the devices controller settings for this service.
#rc_cgroup_devices=""

# Set the hugetlb controller settings for this service.
#rc_cgroup_hugetlb=""

# Set the memory controller settings for this service.
#rc_cgroup_memory=""

# Set the net_cls controller settings for this service.
#rc_cgroup_net_cls=""

# Set the net_prio controller settings for this service.
#rc_cgroup_net_prio=""

# Set the pids controller settings for this service.
#rc_cgroup_pids=""

# Set this to YES if you want all of the processes in a service's cgroup
# killed when the service is stopped or restarted.
# Be aware that setting this to yes means all of a service's
# child processes will be killed. Keep this in mind if you set this to
# yes here instead of for the individual services in
# /etc/conf.d/<service>.
# To perform this cleanup manually for a stopped service, you can
# execute cgroup_cleanup with /etc/init.d/<service> cgroup_cleanup or
# rc-service <service> cgroup_cleanup.
# The process followed in this cleanup is the following:
# 1. send stopsig (sigterm if it isn't set) to all processes left in the
# cgroup immediately followed by sigcont.
# 2. Send sighup to all processes in the cgroup if rc_send_sighup is
# yes.
# 3. delay for rc_timeout_stopsec seconds.
# 4. send sigkill to all processes in the cgroup unless disabled by
# setting rc_send_sigkill to no.
# rc_cgroup_cleanup="NO"

# If this is yes, we will send sighup to the processes in the cgroup
# immediately after stopsig and sigcont.
#rc_send_sighup="NO"

# This is the amount of time in seconds that we delay after sending sigcont
# and optionally sighup, before we optionally send sigkill to all
# processes in the # cgroup.
# The default is 90 seconds.
#rc_timeout_stopsec="90"

# If this is set to no, we do not send sigkill to all processes in the
# cgroup.
#rc_send_sigkill="YES"
EOF
makefile root:root 0644 "$tmp"/etc/sysctl.conf <<EOF
# Maximum TCP Receive Window
net.core.rmem_max = 33554432
# Maximum TCP Send Window
net.core.wmem_max = 33554432
# others
net.ipv4.tcp_rmem = 4096 16384 33554432
net.ipv4.tcp_wmem = 4096 16384 33554432
net.ipv4.tcp_syncookies = 1
# this gives the kernel more memory for tcp which you need with many (100k+) open socket connections
net.ipv4.tcp_mem = 786432 1048576 26777216
net.ipv4.tcp_max_tw_buckets = 360000
net.core.netdev_max_backlog = 2500
vm.min_free_kbytes = 65536
vm.swappiness = 0
net.ipv4.ip_local_port_range = 1024 65535
net.core.somaxconn = 65535
EOF

mkdir -p "$tmp"/etc/cloudi/
makefile root:root 0600 "$tmp"/etc/cloudi/cloudi_tests.conf <<EOF
%-*-Mode:erlang;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
% ex: set ft=erlang fenc=utf-8 sts=4 ts=4 sw=4 et nomod:
{acl, [
    % Access Control Lists (ACLs) define service name prefixes that can be
    % referenced instead of the literal service name prefixes for the
    % destination allow list and/or the destination deny list.  The ACLs may
    % reference other ACLs (cyclic references and missing references
    % in this list generate errors).  ACLs can be provided as service name
    % patterns to match before a send operation and non-patterns are made
    % into service name patterns by appending a '*' character.
    {all, [database, tests]},
    {database, ["/db/*"]},
    {tests, ["/tests/*"]},
    {api, ["/cloudi/api/*"]}
]}.
{services, [
    % an internal service is a native Erlang service,
    % using the cloudi_service behavior

    % this particular service handles the CloudI Service API which provides
    % dynamic configuration of CloudI
    {internal,
        % prefix specified for all subscriptions
        "/cloudi/api/",
        % module name of a module in a reachable path
        cloudi_service_api_requests,
        % module arguments are supplied as a list for the
        % cloudi_service_init/2 function
        [],
        % destination refresh controls how quickly service membership propogates
        % Any process that sends to long-lived processes can use
        % a 'lazy' prefix destination refresh (otherwise, if sending to
        % short-lived provesses, use an 'immediate' prefix destination refresh).
        % The 'lazy' prefix makes the service cache service name lookup data
        % while the 'immediate' prefix uses a central local process to do 
        % service name lookups.
        % A 'closest' suffix destination refresh always prefers local
        % processes rather than using remote processes
        % (processes on other nodes).
        % A 'furthest' suffix destination refresh always prefers remote
        % processes rather than using local processes.
        % A 'random' suffix load balances across all connected nodes.
        % A 'local' suffix will only send to local processes, which will
        % cause less request latency.
        % A 'remote' suffix will always send to remote processes, which can
        % provide more fault-tolerance guarantees.
        % If the process doesn't send to any other processes, then 'none' can
        % be used and the process will die if it attempts to send to another
        % process (it is as if the destination deny list contains all services).
        % (so the choices are:
        %  'lazy_closest', 'immediate_closest',
        %  'lazy_furthest', 'immediate_furthest',
        %  'lazy_random', 'immediate_random',
        %  'lazy_local', 'immediate_local',
        %  'lazy_remote', 'immediate_remote',
        %  'lazy_newest', 'immediate_newest',
        %  'lazy_oldest', 'immediate_oldest',
        %  'none')
        none,
        % timeout for executing the cloudi_service_init/2 function
        5000,
        % default timeout for asynchronous calls
        5000,
        % default timeout for synchronous calls
        5000,
        % destination deny list is used as an ACL (Access Control List) that
        % prevents the process from sending to destinations with the specified
        % prefixes.  if atoms are used within the list, they must exist as an
        % associative entry in the acl configuration list.
        % if the destination deny list is 'undefined' any destination is valid.
        % a blocked request will just return a timeout
        % (earlier than the timeout specified for the request).
        undefined,
        % destination allow list is used as an ACL (Access Control List) that
        % allows the process to send to destinations with the specified
        % prefixes.  if atoms are used within the list, they must exist as an
        % associative entry in the acl configuration list.
        % if the destination allow list is 'undefined' any destination is valid.
        % a blocked request will just return a timeout
        % (earlier than the timeout specified for the request).
        undefined,
        % specify how many processes should be created with this configuration
        1,
        % If more than MaxR restarts occur within MaxT seconds,
        % CloudI terminates the process
        % MaxR (maximum restarts)
        5,
        % MaxT (maximum time)
        300, % seconds
        % options, e.g.:
        % {queue_limit, 1024} % to limit the service's queue to a maximum
        %                     % of 1024 requests (to prevent excessive memory
        %                     % consumption while the service is busy,
        %                     % handling a previous request)
        % (see config_service_options in
        %  lib/cloudi_core/src/cloudi_configuration.hrl)
        []},
    {internal,
        "/cloudi/api/",
        cloudi_service_api_batch,
        [],
        none, 5000, 5000, 5000, undefined, undefined, 1, 5, 300,
        []},

    % an external service is an OS process connected
    % with a socket to the loopback device for each thread
    % the service below processes the Hexidecimal digits of PI (as a test)
    %{external,
    %    % prefix specified for all subscriptions
    %    "/tests/",
    %    % executable file path
    %    "/usr/lib/cloudi-1.8.0/tests/hexpi/hexpi_cxx",
    %    % command line arguments for the executable
    %    "",
    %    % {Key, Value} pairs to specify environment variables
    %    [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
    %     {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
    %    % destination refresh controls how quickly service membership propogates
    %    % Any process that sends to long-lived processes can use
    %    % a 'lazy' prefix destination refresh (otherwise, if sending to
    %    % short-lived provesses, use an 'immediate' prefix destination refresh).
    %    % The 'lazy' prefix makes the service cache service name lookup data
    %    % while the 'immediate' prefix uses a central local process to do 
    %    % service name lookups.
    %    % A 'closest' suffix destination refresh always prefers local
    %    % processes rather than using remote processes
    %    % (processes on other nodes).
    %    % A 'furthest' suffix destination refresh always prefers remote
    %    % processes rather than using local processes.
    %    % A 'random' suffix load balances across all connected nodes.
    %    % A 'local' suffix will only send to local processes, which will
    %    % cause less request latency.
    %    % A 'remote' suffix will always send to remote processes, which can
    %    % provide more fault-tolerance guarantees.
    %    % If the process doesn't send to any other processes, then 'none' can
    %    % be used and the process will die if it attempts to send to another
    %    % process (it is as if the destination deny list contains all services).
    %    % (so the choices are:
    %    %  'lazy_closest', 'immediate_closest',
    %    %  'lazy_furthest', 'immediate_furthest',
    %    %  'lazy_random', 'immediate_random',
    %    %  'lazy_local', 'immediate_local',
    %    %  'lazy_remote', 'immediate_remote',
    %    %  'lazy_newest', 'immediate_newest',
    %    %  'lazy_oldest', 'immediate_oldest',
    %    %  'none')
    %    none,
    %    % protocol used for each socket
    %    tcp,
    %    % buffer size used for each socket
    %    default, % bytes
    %    % timeout for receiving an initialization message from a socket
    %    20000,
    %    % default timeout for asynchronous calls
    %    5000,
    %    % default timeout for synchronous calls
    %    5000,
    %    % destination deny list is used as an ACL (Access Control List) that
    %    % prevents the process from sending to destinations with the specified
    %    % prefixes.  if atoms are used within the list, they must exist as an
    %    % associative entry in the acl configuration list.
    %    % if the destination deny list is 'undefined' any destination is valid.
    %    % a blocked request will just return a timeout
    %    % (earlier than the timeout specified for the request).
    %    undefined, % with 'none' destination refresh method, this is not checked
    %    % destination allow list is used as an ACL (Access Control List) that
    %    % allows the process to send to destinations with the specified
    %    % prefixes.  if atoms are used within the list, they must exist as an
    %    % associative entry in the acl configuration list.
    %    % if the destination allow list is 'undefined' any destination is valid.
    %    % a blocked request will just return a timeout
    %    % (earlier than the timeout specified for the request).
    %    undefined,
    %    % specify how many processes should be created with this configuration
    %    % (a float is a multiplier for the erlang VM scheduler count, i.e.,
    %    %  the desired cpu count)
    %    1,
    %    % specify how many threads should be created with this configuration
    %    % (i.e., how many sockets should be opened to each OS process)
    %    % (a float is a multiplier for the erlang VM scheduler count, i.e.,
    %    %  the desired cpu count)
    %    0.5,
    %    % If more than MaxR restarts occur within MaxT seconds,
    %    % CloudI terminates the process
    %    % MaxR (maximum restarts)
    %    5,
    %    % MaxT (maximum time)
    %    300, % seconds
    %    % options, e.g.:
    %    % {queue_limit, 1024} % to limit the service's queue to a maximum
    %    %                     % of 1024 requests (to prevent excessive memory
    %    %                     % consumption while the service is busy,
    %    %                     % handling a previous request)
    %    % (see config_service_options in
    %    %  lib/cloudi_core/src/cloudi_configuration.hrl)
    %    [{request_timeout_adjustment, true},
    %     {nice, 15}%,
    %     %{cgroup,
    %     % [{name, "cloudi/integration_tests/hexpi"},
    %     %  {parameters,
    %     %   [{"memory.limit_in_bytes", "64m"}]}]}
    %    ]},
    % (using the proplist method of specifying the configuration data...
    %  it provides defaults automatically)
    [%{type, internal}, % gets inferred
     {prefix, "/cloudi/"},
     {module, cloudi_service_filesystem},
     {args,
      [{directory, "/usr/lib/cloudi-1.8.0/service_api/dashboard/"}]},
     {dest_refresh, none},
     {count_process, 4}],
    [{prefix, "/cloudi/log/"},
     {module, cloudi_service_filesystem},
     {args,
      [{directory, "/var/log/cloudi/"},
       {read, [{"/cloudi/log/cloudi.log", -16384}]},
       {refresh, 10}]},
     {dest_refresh, none}],
    [{prefix, "*"},
     {module, cloudi_service_null},
     {args, [{debug, true}, {debug_contents, true}]},
     {dest_refresh, none},
     {options, [{response_timeout_immediate_max, limit_min}]}],
    [{prefix, "/tests/websockets/"},
     {module, cloudi_service_http_cowboy1},
     {args, 
      [{port, 6464}, {output, external}, {use_websockets, true},
       {query_get_format, text_pairs},
       {use_x_method_override, true},
       {websocket_connect_sync,
        "/tests/websockets/bounce/websocket/connect"},
       {websocket_disconnect_async,
        "/tests/websockets/bounce/websocket/disconnect"},
       {websocket_ping, 30000}, % milliseconds
       {websocket_subscriptions,
        [% also, subscribe to "on" a "bounce"
         {"b*u*ce", % <-- valid pattern
          [{parameters_selected, [1, 2]},
           {service_name,
            % wildcards for substitution don't need to be in a valid pattern
            "**/websocket"}]},
         % second subscription, "notification"
         {"b*u*ce",
          [{parameters_selected, [2, 1]},
           {service_name,
            "**tification/websocket"}]}
         ]}]},
     {timeout_sync, 30000}],
    % tests/http/ services
    {internal,
        "/tests/http/",
        cloudi_service_http_cowboy1,
        [{port, 6466}, {output, external},
         {query_get_format, text_pairs},
         {use_x_method_override, true}],
        immediate_closest,
        5000, 5000, 5000, [api], undefined, 1, 5, 300,
        []},
    {internal,
        "/tests/http/",
        cloudi_service_http_cowboy1,
        [{port, 6467}, {output, internal},
         {query_get_format, text_pairs},
         {use_x_method_override, true}],
        immediate_closest, % quickstart testing, to avoid false negatives
        5000, 5000, 5000, undefined, undefined, 1, 5, 300,
        []},
    {internal,
        "/tests/http/",
        cloudi_service_http_elli,
        [{port, 6468}, {output, external},
         {query_get_format, text_pairs},
         {use_x_method_override, true}],
        immediate_closest,
        5000, 5000, 5000, [api], undefined, 1, 5, 300,
        []},
    {internal,
        "/queue",
        cloudi_service_queue,
        [% a maximum of 3 retries will occur if the service request
         % fails to receive a response within the timeout period
         % (e.g., the destination service crashes without providing a response)
         {retry, 3},
         % a write ahead logging (WAL) file path for all requests
         % (n.b., for efficiency reasons all requests are also held in memory)
         {file, "/usr/lib/cloudi-1.8.0/logs/example_queue_\${I}.log"},
         {compression, 6},
         {checksum, crc32}],
        immediate_closest,
        5000, 5000, 5000, undefined, undefined, 4, 5, 300,
        % make sure the cloudi_service_queue gets a timeout as
        % quickly as possible to allow it to retry
        [{request_timeout_immediate_max, limit_min},
         {response_timeout_immediate_max, limit_min}]},
    {internal,
        "/byzantine",
        cloudi_service_quorum,
        [{quorum, byzantine}],
        immediate_closest,
        5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
    {external,
        "/tests/http/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/http/http.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 15}]},
    %{external,
    %    "/tests/http/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/http/java/http.jar",
    %    [],
    %    none, default, default,
    %    20000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
    %    [{nice, 15}]},
    {external,
        "/tests/http/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/http/http.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 15}]},
    %[{prefix, "/tests/count/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/count/count_go"},
    % {dest_refresh, none},
    % {count_thread, 4},
    % {env, [{"GOMAXPROCS", "4"}]},
    % {options, [{nice, 10}]}],
    %[{prefix, "/tests/count/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/count/count_haskell"},
    % {dest_refresh, none},
    % {count_thread, 4},
    % {options, [{nice, 10}]}],
    %[{prefix, "/tests/count/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/count/count_ocaml"},
    % {dest_refresh, none},
    % {count_thread, 4},
    % {options, [{nice, 10}]}],
    {external,
        "/tests/count/",
        "/usr/lib/cloudi-1.8.0/tests/count/count_c", "",
        [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
         {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 4, 1, 5, 300,
        [{nice, 10}]},
    %{external,
    %    "/tests/count/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/count/java/count.jar",
    %    [],
    %    none, default, default,
    %    20000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
    %    [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/node",
        "/usr/lib/cloudi-1.8.0/tests/count/count.js",
        [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 4, 1, 5, 300,
        [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/perl",
        "/usr/lib/cloudi-1.8.0/tests/count/CountTask.pm",
        [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/php",
        "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
        "-f /usr/lib/cloudi-1.8.0/tests/count/count.php",
        [],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 4, 1, 5, 300,
        [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/count/count.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/count/count_c.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 10}]},
    {external,
        "/tests/count/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/count/count.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 4, 5, 300,
        [{nice, 10}]},
    {internal,
        "/tests/count/",
        cloudi_service_test_count,
        [],
        none, 5000, 5000, 5000, undefined, undefined, 4, 5, 300,
        []},
    %[{prefix, "/tests/http_req/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/http_req/http_req_go"},
    % {dest_refresh, none},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {nice, 10}]}],
    %[{prefix, "/tests/http_req/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/http_req/http_req_haskell"},
    % {dest_refresh, none},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {nice, 10}]}],
    %[{prefix, "/tests/http_req/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/http_req/http_req_ocaml"},
    % {dest_refresh, none},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {nice, 10}]}],
    {external,
        "/tests/http_req/",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req_c", "",
        [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
         {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    %{external,
    %    "/tests/http_req/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/http_req/java/http_req.jar",
    %    [],
    %    none, default, default,
    %    20000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/node",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req.js",
        [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/perl",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req.pl",
        [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/php",
        "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
        "-f /usr/lib/cloudi-1.8.0/tests/http_req/http_req.php",
        [],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req_c.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined,
        1.0, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {count_process_dynamic,
          [{rate_request_max, 1.1},
           {rate_request_min, 0.9},
           {count_max, 4.0},
           {count_min, 0.25}]},
         {nice, 10}]},
    {external,
        "/tests/http_req/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/http_req/http_req.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{request_timeout_adjustment, true},
         {nice, 10}]},
    {internal,
        "/tests/http_req/",
        cloudi_service_test_http_req,
        [],
        none,
        limit_max, limit_max, limit_max, % test limits
        undefined, undefined, 1.0, 5, 300,
        [{timeout_terminate, limit_max},
         {request_timeout_adjustment, true},
         {hibernate,
          [{rate_request_min, 0.9}]},
         {count_process_dynamic,
          [{rate_request_max, 1.1},
           {rate_request_min, 0.9},
           {count_max, 2.0},
           {count_min, 0.25}]}]},
    {internal,
        "/tests/http_req/",
        cloudi_service_test_http_req,
        [],
        none,
        limit_min, limit_min, limit_min, % test limits
        undefined, undefined, 1.0, 5, 300,
        [{timeout_terminate, limit_min},
         {request_timeout_adjustment, true},
         {hibernate,
          [{rate_request_min, 0.9}]},
         {count_process_dynamic,
          [{rate_request_max, 1.1},
           {rate_request_min, 0.9},
           {count_max, 2.0},
           {count_min, 0.25}]}]},
    %[{prefix, "/tests/null/response/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_go"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_min},
    %   {nice, 10}]}],
    %[{prefix, "/tests/null/timeout/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_go"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_max},
    %   {nice, 10}]}],
    %[{prefix, "/tests/null/response/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_haskell"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_min},
    %   {nice, 10}]}],
    %[{prefix, "/tests/null/timeout/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_haskell"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_max},
    %   {nice, 10}]}],
    %[{prefix, "/tests/null/response/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_ocaml"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_min},
    %   {nice, 10}]}],
    %[{prefix, "/tests/null/timeout/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/null/null_ocaml"},
    % {dest_refresh, none},
    % {options,
    %  [{response_timeout_immediate_max, limit_max},
    %   {nice, 10}]}],
    {external,
        "/tests/null/response/",
        "/usr/lib/cloudi-1.8.0/tests/null/null_c", "",
        [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
         {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    %{external,
    %    "/tests/null/response/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/null/java/null_.jar",
    %    [],
    %    none, default, default,
    %    20000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
    %    [{response_timeout_immediate_max, limit_min},
    %     {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/node",
        "/usr/lib/cloudi-1.8.0/tests/null/null.js",
        [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/perl",
        "/usr/lib/cloudi-1.8.0/tests/null/null.pl",
        [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/php",
        "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
        "-f /usr/lib/cloudi-1.8.0/tests/null/null.php",
        [],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/null/null.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/null/null_c.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {external,
        "/tests/null/response/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/null/null.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min},
         {nice, 10}]},
    {internal,
        "/tests/null/response/",
        cloudi_service_test_null,
        [],
        none, 5000, 5000, 5000, undefined, undefined, 1, 5, 300,
        [{response_timeout_immediate_max, limit_min}]},
    {external,
        "/tests/null/timeout/",
        "/usr/lib/cloudi-1.8.0/tests/null/null_c", "",
        [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
         {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    %{external,
    %    "/tests/null/timeout/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/null/java/null_.jar",
    %    [],
    %    none, default, default,
    %    20000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
    %    [{response_timeout_immediate_max, limit_max},
    %     {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/node",
        "/usr/lib/cloudi-1.8.0/tests/null/null.js",
        [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/perl",
        "/usr/lib/cloudi-1.8.0/tests/null/null.pl",
        [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/php",
        "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
        "-f /usr/lib/cloudi-1.8.0/tests/null/null.php",
        [],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/null/null.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/null/null_c.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {external,
        "/tests/null/timeout/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/null/null.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max},
         {nice, 10}]},
    {internal,
        "/tests/null/timeout/",
        cloudi_service_test_null,
        [],
        none, 5000, 5000, 5000, undefined, undefined, 1, 5, 300,
        [{response_timeout_immediate_max, limit_max}]},
    {internal,
        "/tests/",
        cloudi_service_router,
        [{destinations,
          [{"http_req/any.xml/get",
            [{mode, round_robin},
             {service_names,
              ["http_req/c.xml/get",
    %           "http_req/java.xml/get",
               "http_req/perl.xml/get",
               "http_req/php.xml/get",
               "http_req/python.xml/get",
               "http_req/python_c.xml/get",
               "http_req/ruby.xml/get"]}]},
           {"null/response/any/get",
            [{mode, round_robin},
             {service_names,
              ["null/response/c/get",
    %           "null/response/java/get",
               "null/response/perl/get",
               "null/response/php/get",
               "null/response/python/get",
               "null/response/python_c/get",
               "null/response/ruby/get"]}]},
           {"null/timeout/any/get",
            [{mode, round_robin},
             {service_names,
              ["null/timeout/c/get",
    %           "null/timeout/java/get",
               "null/timeout/perl/get",
               "null/timeout/php/get",
               "null/timeout/python/get",
               "null/timeout/python_c/get",
               "null/timeout/ruby/get"]}]}]}],
        immediate_closest,
        5000, 5000, 5000, [api], undefined, 1, 5, 300,
        [{request_name_lookup, async}]},
    % normal echo in python
    {external,
        "/tests/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/echo/echo.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        [{nice, 15}]},
    % unstable 50% chance (coin toss) echo in python
    {external,
        "/tests/coin/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/echo/echo.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        none, default, default,
        5000, 5000, 5000, undefined, undefined, 1, 1, 5, 300,
        % give this service instance a 50% of failure on a service request
        [{monkey_chaos, [{probability_request, 0.5}]},
         {nice, 15}]},
    %{internal,
    %    "/tests/http_req/",
    %    cloudi_service_filesystem,
    %    [{directory, "/usr/lib/cloudi-1.8.0/tests/http_req/public_html/"},
    %     {write_append, ["/tests/http_req/hexpi.txt"]},
    %     {refresh, 5}, % seconds
    %     {cache, 300}, % seconds
    %     {notify_one, [{"/tests/http_req/index.html/get", "/tests/echo/put"}]}
    %     ],
    %    immediate_closest,
    %    5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
    %{internal,
    %    "/db/pgsql/",
    %    cloudi_service_db_pgsql,
    %    [{hostname, "127.0.0.1"},
    %     {username, "cloudi_tests"},
    %     {password, "cloudi_tests"},
    %     {port, 5432},
    %     {database, "cloudi_tests"}],
    %    none,
    %    5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
    % the service below manages the Hexidecimal PI test
    %[{prefix, "/tests/"},
    % {module, cloudi_service_map_reduce},
    % {args, [{map_reduce, cloudi_service_test_hexpi}, % map-reduce module
    %         {map_reduce_args, [1, 65536]},  % index start, index end
    %         {name, "hexpi_control"}, % suspend/resume service name
    %         {concurrency, 1.5}]},
    % {timeout_init, 20000},
    % {dest_list_deny, [api]},
    % {options, [{request_timeout_adjustment, true}]}],
    {external,
        "/tests/websockets/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/websockets/websockets.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        immediate_local, default, default,
        5000, 5000, 5000, [api], undefined, 1, 4, 5, 300,
        [{nice, 15}]},
    % openrc-run ensures no USER environment variable is set
    %{external,
    %    "/tests/environment/",
    %    "/usr/bin/python3",
    %    "/usr/lib/cloudi-1.8.0/tests/environment/environment.py "
    %    "À 'À' \"À\" `À`",
    %    [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
    %     {"LANG", "en_US.UTF-8"},
    %     {"USER", "\${USER}"},
    %     {"\$USER", "user"},
    %     {"\${USER}_\$USER", "user_user"},
    %     {"\$USER\${USER}", "useruser"},
    %     {"\${USER}123\$USER", "user123user"},
    %     {"USER_D", "user_\\\\\$"}, % \\\\ is needed to escape \$
    %     {"USER_", "user_\$"}, % "\$" is ignored
    %     {"\${INVALID1=\$USER'check1'\${INVALID2", "user'check1'"},
    %     {"\$INVALID1=\$USER\"check2\"\$INVALID2}", "user\"check2\""},
    %     {"\$USER/\$USER \$USER`\$USER", "user/user user`user"},
    %     {"À_UNICODE", "true"},
    %     {"UNICODE_À", "true"},
    %     {"UNICODE_CHARACTER", "À"}],
    %    immediate_local, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{nice, 15}]},
    % msg_size tests can not use the udp protocol with the default buffer size
    %[{prefix, "/tests/msg_size/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size_go"},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {scope, cloudi_service_test_msg_size},
    %   {nice, 15}]}],
    %[{prefix, "/tests/msg_size/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size_haskell"},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {scope, cloudi_service_test_msg_size},
    %   {nice, 15}]}],
    %[{prefix, "/tests/msg_size/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size_ocaml"},
    % {options,
    %  [{request_timeout_adjustment, true},
    %   {scope, cloudi_service_test_msg_size},
    %   {nice, 15}]}],
    %{internal,
    %    "/tests/msg_size/",
    %    cloudi_service_test_msg_size,
    %    [],
    %    immediate_closest,
    %    5000, 5000, 5000, [api], undefined, 2, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {duo_mode, true},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {restart_delay, []},
    %     {scope, cloudi_service_test_msg_size}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size_cxx",
    %    "",
    %    [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
    %     {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 2, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/msg_size/java/msg_size.jar",
    %    [],
    %    immediate_closest, default, default,
    %    20000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/node",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size.js",
    %    [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/perl",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size.pl",
    %    [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/php",
    %    "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
    %    "-f /usr/lib/cloudi-1.8.0/tests/msg_size/msg_size.php",
    %    [],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/python3",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size.py",
    %    [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
    %     {"LANG", "en_US.UTF-8"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/python3",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size_c.py",
    %    [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
    %     {"LANG", "en_US.UTF-8"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %{external,
    %    "/tests/msg_size/",
    %    "/usr/bin/ruby",
    %    "/usr/lib/cloudi-1.8.0/tests/msg_size/msg_size.rb",
    %    [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
    %    immediate_closest, default, default,
    %    5000, 5000, 5000, [api], undefined, 1, 1, 5, 300,
    %    [{request_timeout_adjustment, true},
    %     {aspects_init_after,
    %      [{cloudi_service_test_msg_size, aspect_init}]},
    %     {aspects_request_before,
    %      [{cloudi_service_test_msg_size, aspect_request}]},
    %     {aspects_terminate_before,
    %      [{cloudi_service_test_msg_size, aspect_terminate}]},
    %     {scope, cloudi_service_test_msg_size},
    %     {nice, 15}]},
    %[{prefix, "/tests/messaging/go/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/messaging/messaging_go"},
    % {dest_refresh, immediate_local},
    % {timeout_async, 10000},
    % {timeout_sync, 10000},
    % {count_thread, 4},
    % {env, [{"GOMAXPROCS", "4"}]},
    % {options,
    %  [{scope, cloudi_service_test_messaging_go},
    %   {nice, 15}]}],
    %[{prefix, "/tests/messaging/haskell/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/messaging/messaging_haskell"},
    % {dest_refresh, immediate_local},
    % {timeout_async, 10000},
    % {timeout_sync, 10000},
    % {count_thread, 4},
    % {options,
    %  [{scope, cloudi_service_test_messaging_haskell},
    %   {nice, 15}]}],
    %[{prefix, "/tests/messaging/ocaml/"},
    % {file_path, "/usr/lib/cloudi-1.8.0/tests/messaging/messaging_ocaml"},
    % {dest_refresh, immediate_local},
    % {timeout_async, 10000},
    % {timeout_sync, 10000},
    % {count_thread, 4},
    % {options,
    %  [{scope, cloudi_service_test_messaging_ocaml},
    %   {nice, 15}]}],
    {external,
        "/tests/messaging/perl/",
        "/usr/bin/perl",
        "/usr/lib/cloudi-1.8.0/tests/messaging/MessagingTask.pm",
        [{"PERL5LIB", "/usr/lib/cloudi-1.8.0/api/perl/"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
        [{scope, cloudi_service_test_messaging_perl},
         {nice, 15}]},
    {external,
        "/tests/messaging/javascript/",
        "/usr/bin/node",
        "/usr/lib/cloudi-1.8.0/tests/messaging/messaging.js",
        [{"NODE_PATH", "/usr/lib/cloudi-1.8.0/api/javascript/"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 4, 1, 5, 300,
        [{scope, cloudi_service_test_messaging_javascript},
         {nice, 15}]},
    {external,
        "/tests/messaging/php/",
        "/usr/bin/php",
        "-d include_path='/usr/lib/cloudi-1.8.0/api/php/' "
        "-f /usr/lib/cloudi-1.8.0/tests/messaging/messaging.php",
        [],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 4, 1, 5, 300,
        [{scope, cloudi_service_test_messaging_php},
         {nice, 15}]},
    {external,
        "/tests/messaging/python/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/messaging/messaging.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
        [{scope, cloudi_service_test_messaging_python},
         {nice, 15}]},
    {external,
        "/tests/messaging/python_c/",
        "/usr/bin/python3",
        "/usr/lib/cloudi-1.8.0/tests/messaging/messaging_c.py",
        [{"PYTHONPATH", "/usr/lib/cloudi-1.8.0/api/python/"},
         {"LANG", "en_US.UTF-8"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
        [{scope, cloudi_service_test_messaging_python_c},
         {nice, 15}]},
    {external,
        "/tests/messaging/ruby/",
        "/usr/bin/ruby",
        "/usr/lib/cloudi-1.8.0/tests/messaging/messaging.rb",
        [{"RUBYLIB", "/usr/lib/cloudi-1.8.0/api/ruby/"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
        [{scope, cloudi_service_test_messaging_ruby},
         {nice, 15}]},
    {external,
        "/tests/messaging/cxx/",
        "/usr/lib/cloudi-1.8.0/tests/messaging/messaging_cxx",
        "",
        [{"LD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"},
         {"DYLD_LIBRARY_PATH", "/usr/lib/cloudi-1.8.0/api/c/"}],
        immediate_local, default, default,
        5000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
        [{scope, cloudi_service_test_messaging_cxx},
         {nice, 15}]},
    %{external,
    %    "/tests/messaging/java/",
    %    "/usr/lib/jvm/java-1.8-openjdk/bin/java",
    %    % based on http://www.infoq.com/articles/benchmarking-jvm
    %    "-Xbatch -server -Xmx1G -Xms1G "
    %    % enable assertions
    %    "-ea:org.cloudi... "
    %    "-jar /usr/lib/cloudi-1.8.0/tests/messaging/java/messaging.jar",
    %    [],
    %    immediate_local, default, default,
    %    20000, 10000, 10000, [api], undefined, 1, 4, 5, 300,
    %    [{scope, cloudi_service_test_messaging_java},
    %     {nice, 15}]},
    {internal,
        "/tests/messaging/erlang/variation0/",
        cloudi_service_test_messaging_sequence1,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, false},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation0}]},
    {internal,
        "/tests/messaging/erlang/variation0/",
        cloudi_service_test_messaging_sequence2,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, false},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation0}]},
    {internal,
        "/tests/messaging/erlang/variation0/",
        cloudi_service_test_messaging_sequence3,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, false},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation0}]},
    {internal,
        "/tests/messaging/erlang/variation0/",
        cloudi_service_test_messaging_sequence4,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, false},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation0}]},
    {internal,
        "/tests/messaging/erlang/variation1/",
        cloudi_service_test_messaging_sequence1,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation1}]},
    {internal,
        "/tests/messaging/erlang/variation1/",
        cloudi_service_test_messaging_sequence2,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation1}]},
    {internal,
        "/tests/messaging/erlang/variation1/",
        cloudi_service_test_messaging_sequence3,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation1}]},
    {internal,
        "/tests/messaging/erlang/variation1/",
        cloudi_service_test_messaging_sequence4,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 1000},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation1}]},
    {internal,
        "/tests/messaging/erlang/variation2/",
        cloudi_service_test_messaging_sequence1,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 4},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation2}]},
    {internal,
        "/tests/messaging/erlang/variation2/",
        cloudi_service_test_messaging_sequence2,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 4},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation2}]},
    {internal,
        "/tests/messaging/erlang/variation2/",
        cloudi_service_test_messaging_sequence3,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 4},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation2}]},
    {internal,
        "/tests/messaging/erlang/variation2/",
        cloudi_service_test_messaging_sequence4,
        [],
        immediate_local,
        5000, 10000, 10000, [api], undefined, 4, 5, 300,
        [{application_name, cloudi_service_test_messaging_sequence},
         {duo_mode, true},
         {hibernate, true},
         {request_pid_uses, 4},
         {reload, true},
         {timeout_terminate, 10},
         {scope, cloudi_service_test_messaging_erlang_variation2}]}
]}.
% automatic node detection with a UDP multicast group
{nodes, automatic}.
% is equivalent to:
%{nodes, [{discovery, [{multicast, []}]}]}.
% manually specified node names
%{nodes, ['cloudi@host1', 'cloudi@host2']}.
% is equivalent to:
%{nodes, [{nodes, ['cloudi@host1', 'cloudi@host2']}]}.
% (see https://cloudi.org/api.html#2_nodes_set for all the options)
{logging, [
    %{file, "path/to/logfile"},
    %{level, trace}, % levels: off, fatal, error, warn, info, debug, trace
    %{syslog,
    % [{identity, "CloudI"},
    %  {facility, local0},
    %  {level, trace}]}, % CloudI log levels are mapped to syslog levels
    %{formatters,
    % [{any,
    %   [{formatter, cloudi_core_i_logger},
    %    {formatter_config,
    %     [{mode, legacy}]}]},
    %  {['STDOUT'],
    %   [{formatter, cloudi_core_i_logger},
    %    {formatter_config,
    %     [{mode, legacy_stdout}]}]},
    %  {['STDERR'],
    %   [{formatter, cloudi_core_i_logger},
    %    {formatter_config,
    %     [{mode, legacy_stderr}]}]}]},
    %{redirect, undefined}
    {log_time_offset, info}
]}.
EOF

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add networking boot

rc_add ntpd default
rc_add cloudi default

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz

