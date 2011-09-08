
package SDM::Rtm::Jobs;

class SDM::Rtm::Jobs {
    table_name  => 'grid_jobs',
    schema_name => 'Rtm',
    data_source => 'SDM::DataSource::Rtm',
    doc         => 'work with grid jobs',
    id_by => [
        jobid       => { is => 'Number' },
        indexid     => { is => 'Number' },
        clusterid   => { is => 'Number' },
        submit_time => { is => 'Number' },
    ],
    has_optional => [
        allocation_path => {
            is => 'Text',
            calculate_from => 'errFile',
            calculate => q| $errFile =~ /^(.*)\/logs/; return $1; |,
        },
        build_id => {
            is => 'Text',
            calculate_from => 'projectName',
            calculate => q| $projectName =~ /^build(\d+)/; return $1; |,
        },
        #allocation_id => {
        #    # FIXME: UR needs to support linking to non id properties, feature request.
        #    is => 'List',
        #    calculate_from => 'build_id',
        #    calculate => q| return unless ($build_id); my @a = SDM::Disk::Allocation->get( owner_id => $build_id ); return map { $_->id } @a; |,
        #},
        mount_path      => {
            is => 'Text',
            calculate_from => 'allocation_path',
            calculate => q| return unless ($allocation_path); join("/",  @{ [ split("/", $allocation_path ) ] }[0..2] ); |,
        },
        volume_id       => {
            is => 'Number',
            calculate_from => 'mount_path',
            calculate => q| my @v = SDM::Disk::Volume->get(mount_path => $mount_path); return map { $_->id } @v; |,
        },
        volume          => { is => 'SDM::Disk::Volume', id_by => 'volume_id' },
        filername       => { via => 'volume' },
        filer           => { is => 'SDM::Disk::Filer', via => 'volume' },
        gpfs_disk_perf_id => {
            is => 'Number',
            calculate_from => ['mount_path','filername'],
            calculate => q| my @g = SDM::Disk::GpfsDiskPerf->get( filername => $filername, mount_path => $mount_path ); return map { $_->id } @g; |,
        },
        gpfs_disk_perf  => { is => 'SDM::Disk::GpfsDiskPerf', id_by => 'gpfs_disk_perf_id' },
        process         => { is => 'SDM::Service::Lsof::Process', id_by => [ 'exec_host', 'jobPid' ] },
        nfsd            => { is => 'Text', via => 'process' },
        host            => { is => 'SDM::Rtm::Host', id_by => [ 'exec_host', 'clusterid' ] },
    ],
    has => [
        options         => { is => 'Number' },
        options2        => { is => 'Number' },
        options3        => { is => 'Number' },
        user            => { is => 'Text' },
        stat            => { is => 'Text' },
        prev_stat       => { is => 'Text' },
        stat_changes    => { is => 'Number' },
        flapping_logged => { is => 'Number' },
        exitStatus      => { is => 'Number' },
        pendReasons     => { is => 'Text' },
        queue           => { is => 'Text' },
        nice            => { is => 'Text' },
        from_host       => { is => 'Text' },
        exec_host       => { is => 'Text' },
        execUid         => { is => 'Number' },
        loginShell      => { is => 'Text' },
        execHome        => { is => 'Text' },
        execCwd         => { is => 'Text' },
        cwd             => { is => 'Text' },
        postExecCmd     => { is => 'Text' },
        execUsername    => { is => 'Text' },
        mailUser        => { is => 'Text' },
        jobname         => { is => 'Text' },
        jobPriority     => { is => 'Number' },
        jobPid          => { is => 'Number' },
        userPriority    => { is => 'Number' },
        projectName     => { is => 'Text' },
        parentGroup     => { is => 'Text' },
        sla             => { is => 'Text' },
        jobGroup        => { is => 'Text' },
        licenseProject  => { is => 'Text' },
        command         => { is => 'Text' },
        newCommand      => { is => 'Text' },
        inFile          => { is => 'Text' },
        outFile         => { is => 'Text' },
        errFile         => { is => 'Text' },
        preExecCmd      => { is => 'Text' },
        res_requirements => { is => 'Text' },
        dependCond      => { is => 'Text' },
        mem_used        => { is => 'Number' },
        swap_used       => { is => 'Number' },
        max_memory      => { is => 'Number' },
        max_swap        => { is => 'Number' },
        mem_requested       => { is => 'Number' },
        mem_requested_oper  => { is => 'Text' },
        mem_reserved    => { is => 'Number' },
        cpu_used        => { is => 'Number' },
        utime           => { is => 'Number' },
        stime           => { is => 'Number' },
        efficiency      => { is => 'Number' },
        effic_logged    => { is => 'Number' },
        numPIDS         => { is => 'Number' },
        numPGIDS        => { is => 'Number' },
        numThreads      => { is => 'Number' },
        pid_alarm_logged => { is => 'Number' },
        num_nodes       => { is => 'Number' },
        num_cpus        => { is => 'Number' },
        maxNumProcessors => { is => 'Number' },
        reserveTime     => { is => 'Date' },
        predictedStartTime => { is => 'Date'},
        start_time      => { is => 'Date'},
        end_time        => { is => 'Date'},
        beginTime       => { is => 'Date'},
        termTime        => { is => 'Date'},
        completion_time => { is => 'Number' },
        pend_time       => { is => 'Number' },
        psusp_time      => { is => 'Number' },
        run_time        => { is => 'Number' },
        ususp_time      => { is => 'Number' },
        ssusp_time      => { is => 'Number' },
        unkwn_time      => { is => 'Number' },
        hostSpec        => { is => 'Text' },
        rlimit_max_cpu  => { is => 'Number' },
        rlimit_max_wallt => { is => 'Number' },
        rlimit_max_swap  => { is => 'Number' },
        rlimit_max_fsize => { is => 'Number' },
        rlimit_max_data  => { is => 'Number' },
        rlimit_max_stack => { is => 'Number' },
        rlimit_max_core => { is => 'Number' },
        rlimit_max_rss  => { is => 'Number' },
        job_start_logged => { is => 'Number' },
        job_end_logged  => { is => 'Number' },
        job_scan_logged => { is => 'Number' },
        userGroup       => { is => 'Test' },
        last_updated    => { is => 'Date'},
    ],
};

sub allocations {
    # If a job is also a Build, can get allocations by build_id
    my $self = shift;
    return unless ($self->build_id);

    # My allocations
    my @allocations = SDM::Disk::Allocation->get( owner_id => $self->build_id );

    # Read/Write allocations
    #use Genome;
    #my @sr = Genome::SoftwareResult->get( build_ids => $self->build_id );
    #my @sr_ids = map { $_->id } @sr;
    #push @allocations, SDM::Disk::Allocation->get( owner_id => \@sr_ids );

    return @allocations;
}

1;
