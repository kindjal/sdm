
package Sdm::Rtm::Jobsfinished;

class Sdm::Rtm::Jobsfinished {
    table_name  => 'grid_jobs_finished',
    schema_name => 'Rtm',
    data_source => 'Sdm::DataSource::Rtm',
    doc         => 'work with finished grid jobs',
    id_by => [
        jobid       => { is => 'Number' },
        indexid     => { is => 'Number' },
        clusterid   => { is => 'Number' },
        submit_time => { is => 'Number' },
    ],
    has_optional => [
        mount_path      => {
            calculate_from => 'cwd',
            calculate => sub { my $cwd = shift; my @a = split('/',$cwd); return join('/',$a[0],$a[1],$a[2]); },
        },
        volume_id       => { is => 'Number',
            calculate_from => 'mount_path',
            calculate => q| my @v = Sdm::Disk::Volume->get(mount_path => $mount_path); return map { $_->id } @v; |,
        },
        volume          => { is => 'Sdm::Disk::Volume', id_by => 'volume_id' },
        filername       => { via => 'volume' },
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

1;
