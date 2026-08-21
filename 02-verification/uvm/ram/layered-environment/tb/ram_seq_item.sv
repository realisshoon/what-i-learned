class ram_seq_item extends uvm_sequence_item;

    rand logic       we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        if (we) return $sformatf("WRITE addr=0x%02h wdata=0x%02h", addr, wdata);
        else return $sformatf("READ addr=0x%02h rdata=0x%02h", addr, rdata);
    endfunction



endclass
