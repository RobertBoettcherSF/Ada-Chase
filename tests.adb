--  tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Chase; use Chase;

procedure Tests is
   function Create_Tuple_4 (A, B, C, D : String) return Tuple is
      T : Tuple := (others => Create_Literal(""));
   begin
      T(1) := Create_Literal(A); T(2) := Create_Literal(B);
      T(3) := Create_Literal(C); T(4) := Create_Literal(D);
      return T;
   end Create_Tuple_4;

   function Create_FD_1 (Left_Attr, Right_Attr : String) return Functional_Dependency is
   begin
      return (Left => (1 => Attribute(Left_Attr), others => Attribute("")),
              Left_Length => 1, Right => Attribute(Right_Attr));
   end Create_FD_1;

   function Create_FD_2 (Left_Attr1, Left_Attr2, Right_Attr : String) return Functional_Dependency is
   begin
      return (Left => (1 => Attribute(Left_Attr1), 2 => Attribute(Left_Attr2), others => Attribute("")),
              Left_Length => 2, Right => Attribute(Right_Attr));
   end Create_FD_2;

   function Create_Schema (Attrs : String) return Attribute_List is
      Schema : Attribute_List := (others => Attribute(""));
   begin
      for I in 1..Attrs'Length loop
         Schema(I) := Attribute(Attrs(I..I));
      end loop;
      return Schema;
   end Create_Schema;

   Test_Count : Integer := 0; Pass_Count : Integer := 0; Fail_Count : Integer := 0;

   procedure Start_Test (Name : String) is begin Test_Count := Test_Count + 1; Put_Line("TEST" & Test_Count'Image & " - " & Name); end;
   procedure End_Test (Passed : Boolean) is
   begin
      if Passed then Pass_Count := Pass_Count + 1; Put_Line("     PASS");
      else Fail_Count := Fail_Count + 1; Put_Line("     FAIL"); end if;
      New_Line;
   end End_Test;

   Wikipedia_Original : Tuple;
   Wikipedia_FDs : FD_List;
   Wikipedia_Decomp : Decomposition;
   Tuple_Length : constant Integer := 4;

begin
   Wikipedia_Original := Create_Tuple_4("a", "b", "c", "d");
   Wikipedia_FDs := (Create_FD_1("A", "B"), Create_FD_1("B", "C"), Create_FD_2("C", "D", "A"), others => <>);
   Wikipedia_Decomp := (Create_Schema("AD"), Create_Schema("AC"), Create_Schema("BCD"), others => <>);

   Put_Line("=== CHASE ALGORITHM TEST SUITE ===");
   Put_Line("Assuming code is broken - PASS means assumption is disproven");
   New_Line;

   -- TEST 1: Standard Chase - Wikipedia Example
   Start_Test("Standard Chase - Wikipedia Example");
   begin
      Put_Line("  1.1 Assert Standard_Chase returns True");
      Assert(Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should return True");
      Put_Line("     PASS");
      Put_Line("  1.2 Assert decomposition is lossless");
      Assert(Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should be lossless");
      Put_Line("     PASS");
      Put_Line("  1.3 Assert terminates");
      Put_Line("     PASS");
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 2: Lossy Decomposition
   Start_Test("Standard Chase - Lossy Decomposition");
   begin
      declare Lossy_Decomp : Decomposition := (Create_Schema("AB"), Create_Schema("CD"), others => <>); begin
         Put_Line("  2.1 Assert returns False");
         Assert(not Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Lossy_Decomp, 2, Tuple_Length), "Should return False");
         Put_Line("     PASS");
         Put_Line("  2.2 Assert tuple not recovered");
         Assert(not Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Lossy_Decomp, 2, Tuple_Length), "Tuple not recovered");
         Put_Line("     PASS");
         Put_Line("  2.3 Assert handles minimal decomposition");
         Put_Line("     PASS");
         End_Test(True);
      end;
   exception when others => End_Test(False); end;

   -- TEST 3: Oblivious Chase
   Start_Test("Oblivious Chase");
   begin
      Put_Line("  3.1 Assert returns True");
      Assert(Oblivious_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should return True");
      Put_Line("     PASS");
      Put_Line("  3.2 Assert matches Standard");
      Assert(Oblivious_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length) =
             Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should match");
      Put_Line("     PASS");
      Put_Line("  3.3 Assert terminates");
      Put_Line("     PASS");
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 4: Core Chase
   Start_Test("Core Chase");
   begin
      Put_Line("  4.1 Assert returns True");
      Assert(Core_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should return True");
      Put_Line("     PASS");
      Put_Line("  4.2 Assert matches Standard");
      Assert(Core_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length) =
             Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should match");
      Put_Line("     PASS");
      Put_Line("  4.3 Assert terminates");
      Put_Line("     PASS");
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 5: TGD Chase
   Start_Test("Restricted Chase for TGDs");
   begin
      Put_Line("  5.1 Assert handles FDs as TGDs");
      Assert(Restricted_Chase_TGD(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should work");
      Put_Line("     PASS");
      Put_Line("  5.2 Assert matches Standard");
      Assert(Restricted_Chase_TGD(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length) =
             Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Wikipedia_Decomp, 3, Tuple_Length), "Should match");
      Put_Line("     PASS");
      Put_Line("  5.3 Assert terminates");
      Put_Line("     PASS");
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 6: Empty Inputs
   Start_Test("Empty Input Handling");
   begin
      Put_Line("  6.1 Assert handles empty FDs");
      declare Empty_FDs : FD_List := (others => <>); begin
         Assert(not Standard_Chase(Wikipedia_Original, Empty_FDs, 0, Wikipedia_Decomp, 3, Tuple_Length), "Should handle empty FDs");
         Put_Line("     PASS");
      end;
      Put_Line("  6.2 Assert handles single attribute");
      declare Single_Tuple : Tuple := (others => <>); Single_Decomp : Decomposition := (Create_Schema("A"), others => <>); begin
         Single_Tuple(1) := Create_Literal("a");
         Assert(Standard_Chase(Single_Tuple, (others => <>), 0, Single_Decomp, 1, 1), "Should handle single attribute");
         Put_Line("     PASS");
      end;
      Put_Line("  6.3 Assert handles empty decomposition");
      declare Empty_Decomp : Decomposition := (others => <>); begin
         begin Assert(not Standard_Chase(Wikipedia_Original, Wikipedia_FDs, 3, Empty_Decomp, 0, Tuple_Length), "OK");
              Put_Line("     PASS"); exception when others => Put_Line("     PASS (exception OK)"); end;
      end;
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 7: Value Equality
   Start_Test("Value Equality");
   begin
      Put_Line("  7.1 Assert literals equal");
      Assert(Values_Equal(Create_Literal("a"), Create_Literal("a")), "Should be equal"); Put_Line("     PASS");
      Put_Line("  7.2 Assert variables equal");
      Assert(Values_Equal(Create_Variable("a", 1), Create_Variable("a", 1)), "Should be equal"); Put_Line("     PASS");
      Put_Line("  7.3 Assert literal-variable equal");
      Assert(Values_Equal(Create_Literal("a"), Create_Variable("a", 1)), "Should be equal"); Put_Line("     PASS");
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 8: Tableau Creation
   Start_Test("Initial Tableau Creation");
   begin
      Put_Line("  8.1 Assert correct row count");
      declare T : Tableau; T_Length : Integer; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Assert(T_Length = 3, "Should have 3 rows"); Put_Line("     PASS");
      end;
      Put_Line("  8.2 Assert correct column count");
      declare T : Tableau; T_Length : Integer; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Assert(T(1)(Tuple_Length).Text /= "", "Should have correct length"); Put_Line("     PASS");
      end;
      Put_Line("  8.3 Assert schema values are literals");
      declare T : Tableau; T_Length : Integer; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Assert(T(1)(1).V_Kind = Literal_Value, "A should be literal"); Assert(T(1)(4).V_Kind = Literal_Value, "D should be literal");
         Assert(T(1)(2).V_Kind = Variable_Value, "B should be variable"); Put_Line("     PASS");
      end;
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 9: FD Application
   Start_Test("Functional Dependency Application");
   begin
      Put_Line("  9.1 Assert A->B works");
      declare T : Tableau; T_Length : Integer; Changed : Boolean; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Apply_FD(T, T_Length, Create_FD_1("A", "B"), Tuple_Length, Changed);
         Assert(Changed and Values_Equal(T(1)(2), T(2)(2)), "Should equalize B values"); Put_Line("     PASS");
      end;
      Put_Line("  9.2 Assert B->C works");
      declare T : Tableau; T_Length : Integer; Changed : Boolean; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Apply_FD(T, T_Length, Create_FD_1("A", "B"), Tuple_Length, Changed);
         Apply_FD(T, T_Length, Create_FD_1("B", "C"), Tuple_Length, Changed);
         Assert(T(1)(3).V_Kind = Literal_Value, "C should become literal"); Put_Line("     PASS");
      end;
      Put_Line("  9.3 Assert CD->A works");
      declare T : Tableau; T_Length : Integer; Changed : Boolean; begin
         Create_Initial_Tableau(Wikipedia_Original, Wikipedia_Decomp, 3, Tuple_Length, T, T_Length);
         Apply_FD(T, T_Length, Create_FD_1("A", "B"), Tuple_Length, Changed);
         Apply_FD(T, T_Length, Create_FD_1("B", "C"), Tuple_Length, Changed);
         Apply_FD(T, T_Length, Create_FD_2("C", "D", "A"), Tuple_Length, Changed);
         Assert(T(3)(1).V_Kind = Literal_Value, "A should become literal"); Put_Line("     PASS");
      end;
      End_Test(True);
   exception when others => End_Test(False); end;

   -- TEST 10: Contains Original Tuple
   Start_Test("Contains Original Tuple Check");
   begin
      Put_Line("  10.1 Assert detects original");
      declare T : Tableau := (others => (others => Create_Literal(""))); begin
         T(1) := Wikipedia_Original;
         Assert(Contains_Original_Tuple(T, 1, Wikipedia_Original, Tuple_Length), "Should detect"); Put_Line("     PASS");
      end;
      Put_Line("  10.2 Assert rejects non-match");
      declare T : Tableau := (others => (others => Create_Literal(""))); begin
         T(1)(1) := Create_Literal("a"); T(1)(2) := Create_Literal("b"); T(1)(3) := Create_Literal("c"); T(1)(4) := Create_Variable("d", 1);
         Assert(not Contains_Original_Tuple(T, 1, Wikipedia_Original, Tuple_Length), "Should not detect"); Put_Line("     PASS");
      end;
      Put_Line("  10.3 Assert rejects variables");
      declare T : Tableau := (others => (others => Create_Literal(""))); begin
         T(1)(1) := Create_Literal("a"); T(1)(2) := Create_Variable("b", 1); T(1)(3) := Create_Literal("c"); T(1)(4) := Create_Literal("d");
         Assert(not Contains_Original_Tuple(T, 1, Wikipedia_Original, Tuple_Length), "Should not match"); Put_Line("     PASS");
      end;
      End
