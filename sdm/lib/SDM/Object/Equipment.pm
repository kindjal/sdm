
package SDM::Object::Equipment;

class SDM::Object::Equipment {
    has_optional => [
        manufacturer  => { is => 'Text' },
        model         => { is => 'Text' },
        serial        => { is => 'Text' },
        description   => { is => 'Text' },
        comments      => { is => 'Text' },
        location      => { is => 'Text' },
    ]
};

1;
