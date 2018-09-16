--
-- Another stupid Brainfuck interpreter
--

with Ada.Command_Line,
     Ada.Containers.Vectors,
     Ada.Sequential_IO,
     Ada.Text_IO,
     Ada.Strings.Unbounded;

procedure Fucked is
    use Ada.Containers,
        Ada.Text_IO,
        Ada.Strings.Unbounded;

    package CLI renames Ada.Command_Line;
    package Char_IO is new Ada.Sequential_IO (Character);
    package Characters is new Ada.Containers.Vectors (Natural, Character);
    package Numbers is new Ada.Containers.Vectors (Natural, Natural);


    type Cell is mod 2**8;
    type Stack_Type is array (0 .. 30_000) of Cell;
    Stack_Overflow : exception;
    Stack_Underflow : exception;
    GotEOF : Boolean := False;
    GotLine : Boolean := False;
    InpLine : Unbounded_String;

    Code : Characters.Vector;

    procedure putch(ch : Cell) is
    begin
        if ch = 10 then
            Put_Line("");
        else
            Put (Character'Val (ch));
        end if;
    end putch;

    function getch(oldch : Cell) return Cell is
        ch : Cell;
    begin
        ch := oldch;
        if GotEOF then return ch ; end if;
        if Not GotLine then
            begin
                InpLine := To_Unbounded_String(Get_line);
                GotLine := True;
            exception
                when End_Error =>
                    GotEOF := True;
                    return oldch;
            end;
        end if;
        if InpLine = "" then
            GotLine := False;
            return 10;
        end if;
        ch := Character'Pos (Slice(InpLine, 1, 1)(1));
        InpLine := Delete(InpLine, 1, 1);
        return ch;
    end getch;

    procedure Interpret (Code : in Characters.Vector) is
        Stack : Stack_Type := (others => 0);
        Loop_Stack : Numbers.Vector;
        Position, Offset : Natural := 0;
        Current : Cell := 0;
    begin
        while Offset < Natural (Code.Length) loop
            Current := Stack (Position);

            case Code.Element (Offset) is
                -- increment the data pointer (to point to the next cell to the
                -- right).
                when '>' =>
                    Position := Position + 1;
                    Offset := Offset + 1;

                    if Stack'Length < Position then
                        raise Stack_Overflow;
                    end if;

                -- decrement the data pointer (to point to the next cell to the
                -- left)
                when '<' =>
                    if Position = 0 then
                        raise Stack_Underflow;
                    end if;

                    Position := Position - 1;
                    Offset := Offset + 1;

                -- increment (increase by one) the byte at the data pointer.
                when '+' =>
                    Stack (Position) := Current + 1;
                    Offset := Offset + 1;

                -- decrement (decrease by one) the byte at the data pointer.
                when '-' =>
                    Stack (Position) := Current - 1;
                    Offset := Offset + 1;

                -- output a character, the ASCII value of which being the byte at
                -- the data pointer.
                when '.' =>
                    putch (Stack (Position));
                    Offset := Offset + 1;

                -- accept one byte of input, storing its value in the byte at the
                -- data pointer.
                when ',' =>
                    Stack (Position) := getch (Stack (Position));
                    Offset := Offset + 1;

                -- if the byte at the data pointer is zero, then instead of moving
                -- the instruction pointer forward to the next command, jump it
                -- forward to the command after the matching ] command*.
                when '[' =>

                    Offset := Offset + 1;
                    if Current /= 0 then
                        Loop_Stack.Append (Offset - 1);
                    else
                        -- If the counter is back to zero then we need to jump
                        -- ahead to the corresponding ']' for this loop
                        declare
                            Count_Back : Natural := 1;
                        begin
                            while Count_Back > 0 loop
                                case Code.Element (Offset) is
                                    when ']' =>
                                        Count_Back := Count_Back - 1;

                                    when '[' =>
                                        Count_Back := Count_Back + 1;

                                    when others =>
                                        null;
                                end case;

                                Offset := Offset + 1;
                            end loop;
                        end;
                    end if;

                -- if the byte at the data pointer is nonzero, then instead of
                -- moving the instruction pointer forward to the next command,
                -- jump it back to the command after the matching [ command*.
                when ']' =>
                    Offset := Loop_Stack.Element (Integer (Loop_Stack.Length - 1));
                    Numbers.Delete_Last (Loop_Stack);

                when others =>
                    Offset := Offset + 1;

            end case;
        end loop;

    end Interpret;

begin
    if CLI.Argument_Count < 1 then
        Put_Line ("Missing arguments");
        CLI.Set_Exit_Status (1);
        return;
    end if;

    declare
        Script : Char_IO.File_Type;
        Value : Character;
    begin
        Char_IO.Open (Script, Char_IO.In_File, CLI.Argument (1));

        while not Char_IO.End_Of_File (Script) loop
            Char_IO.Read (File => Script, Item => Value);
            Code.Append (Value);
        end loop;

        Char_IO.Close (Script);
    end;

    if Code.Length = 0 then
        Put_Line ("Did not read any value code :(");
        CLI.Set_Exit_Status (1);
        return;
    end if;

    Interpret (Code);

end Fucked;
