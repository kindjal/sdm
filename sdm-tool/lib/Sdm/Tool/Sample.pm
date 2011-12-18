
package Sdm::Tool::Sample;

use Sdm;

class Sdm::Tool::Sample {
    id_by => [ 'pse_id' => { is => 'Text'} ],
    schema_name => 'GMSchema',
    data_source => 'Sdm::DataSource::GMSchema',
    table_name => <<EOS
        (
         SELECT
         oi.common_name as common_name,
         os.organism_sample_id as sample_id,
         woi.barcode,
         woi_pse.pse_id as pse_id,
         pse.psesta_pse_status as status,
         pse.pr_pse_result as result,
         pse.date_scheduled,
         ps.purpose,
         gu.unix_login,
         pj.job_id as lsf_job_id,
         gjf.exec_host as lsf_host,
         gjf.submit_time,
         gjf.start_time,
         gjf.end_time
         FROM gsc.ORGANISM_INDIVIDUAL\@dw oi
         JOIN gsc.ORGANISM_SAMPLE\@dw os ON oi.organism_id = os.source_id
         JOIN gsc.WORK_ORDER_ITEM\@oltp woi ON woi.dna_id = os.organism_sample_id
         JOIN gsc.WOI_PSE\@oltp ON woi.woi_id = woi_pse.woi_id
         JOIN gsc.PROCESS_STEP_EXECUTIONS\@oltp pse ON pse.pse_id = woi_pse.pse_id
         JOIN gsc.PROCESS_STEPS\@oltp ps ON pse.ps_ps_id = ps.ps_id
         JOIN gsc.EMPLOYEE_INFOS\@oltp ei on ei.ei_id = pse.ei_ei_id
         JOIN gsc.GSC_USERS\@oltp gu on gu.gu_id = ei.gu_gu_id
         LEFT OUTER JOIN PSE_JOB\@oltp pj ON pj.pse_id = pse.pse_id
         LEFT OUTER JOIN GRID_JOBS_FINISHED\@dw gjf on gjf.bjob_id = pj.job_id
         ) data
EOS
    ,
    has => [
        common_name => { is => 'Text' },
        sample_id => { is => 'Text' },
        barcode => { is => 'Text' },
        status => { is => 'Text' },
        result => { is => 'Text' },
        purpose => { is => 'Text' },
        date_scheduled => { is => 'Date' },
        unix_login => { is => 'Text' },
        lsf_job_id => { is => 'Number' },
        lsf_host => { is => 'Text' },
        submit_time => { is => 'Text' },
        start_time => { is => 'Text' },
        end_time => { is => 'Text' }
    ],
};

1;
