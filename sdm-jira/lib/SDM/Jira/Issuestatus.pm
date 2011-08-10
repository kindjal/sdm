
package SDM::Jira::Issuestatus;

class SDM::Jira::Issuestatus {
    schema_name => 'Jira',
    data_source => 'SDM::DataSource::Jira',
    table_name => 'issuestatus',
    id_by => [
        id => { is => 'Text' },
    ],
    has => [
        sequence => { is => 'Number' },
        pname => { is => 'Text' },
        description => { is => 'Text' },
        iconurl => { is => 'Text' },
    ],
};

1;
