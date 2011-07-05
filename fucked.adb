--
-- Another stupid Brainfuck interpreter
--

with Ada.Command_Line,
     Ada.Containers.Vectors,
     Ada.Sequential_IO,
     Ada.Text_IO;

procedure Fucked is
    use Ada.Containers,
        Ada.Text_IO;

    package CLI renames Ada.Command_Line;
    package Char_IO is new Ada.Sequential_IO (Character);
    package Characters is new Ada.Containers.Vectors (Natural, Character);
    package Numbers is new Ada.Containers.Vectors (Natural, Natural);


    type Stack_Type is array (0 .. 30_000) of Natural;
    Stack_Overflow : exception;
    Stack_Underflow : exception;
    Not_Implemented : exception;


    Code : Characters.Vector;

    procedure Interpret (Code : Characters.Vector) is
        Stack : Stack_Type;
        Loop_Stack : Numbers.Vector;
        Position, Offset, Current : Natural := 0;
    begin
        while Offset < Natural (Code.Length) loop
            Current := Stack (Position);
            Offset := Offset + 1;

            case Code.Element (Offset - 1) is
                -- increment the data pointer (to point to the next cell to the
                -- right).
                when '>' =>
                    Position := Position + 1;

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

                -- increment (increase by one) the byte at the data pointer.
                when '+' =>
                    Stack (Position) := Current + 1;

                -- decrement (decrease by one) the byte at the data pointer.
                when '-' =>
                    Stack (Position) := Current - 1;

                -- output a character, the ASCII value of which being the byte at
                -- the data pointer.
                when '.' =>
                    Put (Character'Val (Stack (Position)));

                -- accept one byte of input, storing its value in the byte at the
                -- data pointer.
                when ',' =>
                    raise Not_Implemented;

                -- if the byte at the data pointer is zero, then instead of moving
                -- the instruction pointer forward to the next command, jump it
                -- forward to the command after the matching ] command*.
                when '[' =>
                    if Current > 0 then
                        Loop_Stack.Append (Offset);
                    else
                        -- If the counter is back to zero then we need to jump
                        -- ahead to the corresponding ']' for this loop
                        declare
                            Count_Back : Natural := 1;
                        begin
                            while Count_Back > 0 loop
                                case Code.Element (Count_Back) is
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
                    declare
                        Back_To : constant Natural := Loop_Stack.Element (
                                                        Integer (Loop_Stack.Length - 1));
                        Counter : constant Natural := Stack (Position);
                    begin
                        if Counter = 0 then
                            Numbers.Delete_Last (Loop_Stack);
                        else
                            Offset := Back_To;
                        end if;
                    end;

                when others =>
                    null;

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
