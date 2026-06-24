module tb_weapon ();
    class weapon;
        string name;
        function new(string name);
            this.name = name;
        endfunction //new()

        virtual function void shot();
            $display("   [%s] ... (무기 없음)",name);
        endfunction
    endclass //weapon

    class M16 extends weapon;
        function new(string name);
            super.new(name);
        endfunction //new()

        virtual function void shot();
            $display("   [%s] 탕 탕 탕 !!",name);
        endfunction
    endclass //M16 extends weapon

    class AUG extends weapon;
        function new(string name);
            super.new(name);
        endfunction //new()

        virtual function void shot();
            $display("   [%s] Grrrrrrr !!",name);
        endfunction
    endclass //M16 extends weapon

    class K2 extends weapon;
        function new(string name);
            super.new(name);
        endfunction //new()

        virtual function void shot();
            $display("   [%s] 빵 빵 빵 !!",name);
        endfunction
    endclass //M16 extends weapon



    initial begin
        weapon BlackPink = new("No Weapon");

        M16 m16 = new("M16");
        AUG aug = new("AUG");
        K2 k2 = new("K2");

        $display("========== 다형성 데모 ========");
        BlackPink.shot();

        $display("========== 무기 M16으로 변경 ========");
        BlackPink = m16;
        BlackPink.shot();

        $display("========== 무기 aug으로 변경 ========");
        BlackPink = aug;
        BlackPink.shot();

        $display("========== 무기 k2으로 변경 ========");
        BlackPink = k2;
        BlackPink.shot();

        $finish;
    end

endmodule