using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MySql.Data.MySqlClient;
using System.Collections;

namespace streetsharksconsoleapp
{
    class StreetSharksConnection
    {
        private static StreetSharksConnection singletonInstance; //stops the program from having multiple instantiatons of the same connection outside of the connections 
        private String connectionString = "Database=[insert_db_name_here_no_braces];Data Source=[insert_localhost_or_127.0.0.1_or_server_here_no_braces];User Id=[insert_user_id_here_no_braces];Password=[insert_password_here_no_braces]";

        public StreetSharksConnection() {}

        public static StreetSharksConnection Instance //does not work for multi threading situations
        {
            get
            {
                if (Instance == null)
                {
                    singletonInstance = new StreetSharksConnection();
                }
                return singletonInstance;
            }
        }

            public void openConnection()
            {
            MySqlConnection con = new MySqlConnection(connectionString);
            try
                {
                    
                    con.Open();
                    Console.WriteLine("Street sharks utilitiesdb opened...");
                }
                catch (MySqlException error)
                {
                    Console.WriteLine("Error connecting to the database, printing error: " + error.ToString());
                    Console.WriteLine("Printing stack trace: " + error.StackTrace);
                }
                finally
                {
                    if (con != null)
                    {
                        con.Close();
                    }
              }
            }

            private void endProgram()
            {
                Console.WriteLine("Closing connection...thanks for using the streetsharks utilitiesdb!");
            }

            public void printMenuReadInput()
            {
                Console.WriteLine();
                Console.WriteLine("StreetSharks Database Menu\nEnter a menu number option to continue");
                Console.WriteLine("***************************MENU START***************************");
                Console.WriteLine("1 Get workers and equipment checkout");
                Console.WriteLine("2 Get all worker contact info");
                Console.WriteLine("3 Get all utilites and associated tasks (null or not)");
                Console.WriteLine("4 Get all tasks for today");
                Console.WriteLine("5 Get utilities that have tasks assigned");
                Console.WriteLine("6 Get workers and their assignments");
                Console.WriteLine("7 Equipment and Count in Utility Branches");
                Console.WriteLine("8 Describe Tables");
                Console.WriteLine("9 Describe Columns");
                Console.WriteLine("10 Write your own query!");
                Console.WriteLine("11 Close connection and exit program");
                Console.WriteLine("****************************END MENU****************************");
                int menuOption = int.MaxValue;
                try
                {
                    try
                    {
                        menuOption = Int32.Parse(Console.ReadLine().Trim());
                    }
                    catch (Exception intError)
                    {
                        Console.WriteLine("That wasn't an integer value, please try again");
                        this.printMenuReadInput();
                    }
                }
                catch (Exception IOerror)
                {
                    Console.WriteLine("an I/O error occurred, please try again... ");
                    this.printMenuReadInput();
                }
                if (!(this.executeQuery(menuOption)))
                {
                    Console.WriteLine("Oops, that menu option is not available, please try again.\n");
                    this.printMenuReadInput();
                }

            }

        private bool executeQuery(int menuOption)
        {
            //big switch statement
            //could have been implemented with indexing 
            //on arraylist but decided against it
            //because the console app is less connected to the project
            switch (menuOption)
            {
                case 1:
                    query1();
                    return true;
                case 2:
                    query2();
                    return true;
                case 3:
                    query3();
                    return true;
                case 4:
                    query4();
                    return true;
                case 5:
                    query5();
                    return true;
                case 6:
                    query6();
                    return true;
                case 7:
                    query7();
                    return true;
                case 8:
                    descTables();
                    return true;
                case 9:
                    descColumns();
                    return true;
                case 10:
                    writeYourOwnQuery();
                    return true;
                case 11:
                    endProgram();
                    return true;
                default:
                    return false;
            }
        }

        private void query1()
        {
            String cmdText = "select worker.last_name, worker.worker_id, worker.worker_utility_branch_id as utility_branch, equipment.description, equipment_out.count from equipment, worker join equipment_out on worker.worker_id = equipment_out.equipment_out_worker_id where equipment_out.equipment_out_equipment_id = equipment.equipment_id;";
            standardQuery(cmdText);
        }

        private void query2()
        {
            String cmdText = "select w.worker_utility_branch_id as utility_branch, w.worker_id, address.street, address.city, address.state, address.zip_code as zip, address.phone_number as phone from worker w join address on w.worker_address_id = address.address_id order by w.worker_utility_branch_id;";
            standardQuery(cmdText);
        }

        private void query3()
        {
            String cmdText = "select utility.*, task.task_id, task.appointment_date from utility left join task on utility.utility_id = task.task_utility_id;";
            standardQuery(cmdText);
        }

        private void query4()
        {
            String cmdText = "select u.description, u.longitude, u.latitude, w.worker_id, w.last_name, t.appointment_date from utility u, worker w, task t, task_schedule s where DATE(t.appointment_date) = CURRENT_DATE and " +
                            "s.schedule_worker_id = w.worker_id and s.schedule_id = t.task_schedule_id and t.task_utility_id = u.utility_id;";
            standardQuery(cmdText);
        }

        private void query5()
        {
            String cmdText = "select u.description, u.utility_id, u.latitude, u.longitude, e.description as equip_req_desc, er.quantity as amt_needed from utility u, task t, equipment e, equipment_required er where u.utility_id = t.task_utility_id and er.equipment_required_task_id = t.task_id and er.equipment_required_equipment_id = e.equipment_id;";
            standardQuery(cmdText);
        }

        private void query6()
        {
            String cmdText = "select w.first_name, w.last_name, u.description, t.task_id, t.appointment_date from worker w, utility u, task t, task_schedule s where s.schedule_worker_id = w.worker_id and t.task_schedule_id = s.schedule_id and u.utility_id = t.task_utility_id;";
            standardQuery(cmdText);
        }

        private void query7()
        {
            String cmdText = "select u.utility_branch_name, u.utility_branch_id, e.description, e.quantity, eo.count as quantityOut from equipment e, equipment_out eo, utility_branch u where u.utility_branch_id = e.equipment_utility_branch_id and eo.equipment_out_equipment_id = e.equipment_id;";
            standardQuery(cmdText);
        }
        
        private void descTables()
        {
            MySqlConnection con = new MySqlConnection(connectionString);
            try
            {
                con.Open();
                MySqlCommand command = con.CreateCommand();
                command.CommandText = "SHOW TABLES;";
                MySqlDataReader Reader;
                Reader = command.ExecuteReader();
                while (Reader.Read())
                {
                    string row = "";
                    for (int i = 0; i < Reader.FieldCount; i++)
                        row += Reader.GetValue(i).ToString() + ", ";
                    Console.WriteLine(row);
                }
                printMenuReadInput();
            }
            catch (MySqlException msqle)
            {
                Console.WriteLine("There was an error with the connection, please try again...");
                printMenuReadInput();
            }
            finally
            {
                if (con != null)
                {
                    con.Close();
                }
            }
        }

        private void descColumns()
        {
            Console.WriteLine("Type the table name or exit to exit the desc columns option...");
            String tblName = Console.ReadLine();
            if (tblName == "exit")
            {
                printMenuReadInput();
            }
            MySqlConnection con = new MySqlConnection(connectionString);
            try
            {
                con.Open();
                MySqlCommand command = con.CreateCommand();
                command.CommandText = "SHOW FIELDS FROM " + tblName;
                MySqlDataReader Reader;
                Reader = command.ExecuteReader();
                while (Reader.Read())
                {
                    string row = "";
                    for (int i = 0; i < Reader.FieldCount; i++)
                    row += Reader.GetValue(i).ToString() + ", ";
                    Console.WriteLine(row);
                }
                printMenuReadInput();
            }
            catch (MySqlException msqle)
            {
                Console.WriteLine("There was an error with the connection or the table does not exist, please try again...");
                descColumns();
            }
            finally
            {
                if (con != null)
                {
                    con.Close();
                }
            }
            printMenuReadInput();
        }

        private void standardQuery(string query)
        {
            MySqlConnection con = new MySqlConnection(connectionString);
            MySqlDataReader reader = null;
            try
            {
                con.Open();
                Console.WriteLine();
                DateTime start;
                TimeSpan time;
                start = DateTime.Now;
                MySqlCommand cmd = new MySqlCommand(query, con);
                reader = cmd.ExecuteReader(); 
                time = DateTime.Now - start;
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    Console.Write("{0, -20}", reader.GetName(i));
                }
                Console.WriteLine();
                while (reader.Read())
                {
                    for (int j = 0; j < reader.FieldCount; j++)
                    {
                        try {
                            Console.Write("{0, -20}", reader.GetString(j));
                        }
                        catch (Exception msqle)
                        {
                            Console.Write("{0, -20}", "null");
                        }
                    }
                    Console.WriteLine();
                }
                Console.WriteLine("Query Completed in..." + time.TotalMilliseconds + "ms");
                printMenuReadInput();
            }
            catch (MySqlException msqle)
            {
                Console.WriteLine(msqle.ToString());
                Console.WriteLine("There was an error with the connection, please try again...");
                printMenuReadInput();
            }
            finally
            {
                if (con != null)
                {
                    con.Close();
                }
            }
        }

        /**we make an assumption here that a user would check the counts of current values in equipment for a utility branch before adding a row to equipment out or
        updating it. this project was more about the mysql then it was about the console app so we left this part out and if we had another day or two for the project
        we would've added this**/
        private void customQuery(string query)
        {
            MySqlConnection con = new MySqlConnection(connectionString);
            MySqlDataReader reader = null;
                try
                {
                con.Open();
                Console.WriteLine();
                DateTime start;
                TimeSpan time;
                start = DateTime.Now;
                MySqlCommand cmd = new MySqlCommand(query, con);
                reader = cmd.ExecuteReader();
                time = DateTime.Now - start;
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    Console.Write("{0, -20}", reader.GetName(i));
                }
                Console.WriteLine();
                while (reader.Read())
                    {
                    for (int j = 0; j < reader.FieldCount; j++)
                    {
                        try
                        {
                            Console.Write("{0, -20}", reader.GetString(j));
                        }
                        catch (Exception msqle)
                        {
                            Console.Write("{0, -20}", "null");
                        }
                    }
                    Console.WriteLine();
                    }
                Console.WriteLine("Query Completed in..." + time.TotalMilliseconds + "ms");
                printMenuReadInput();
                }
                catch (MySqlException msqle)
                {
                Console.WriteLine(msqle.ToString());
                Console.WriteLine("There was an error with your sql syntax or the connection, please try again...");
                writeYourOwnQuery();
                }
                finally
                {
                    if (con != null)
                    {
                         con.Close();
                    }
                }
            
        }

        private void writeYourOwnQuery()
        {
            Console.WriteLine("Please type MySQL syntax to execute a query of your choosing...type exit; to go back to the menu");
            String query = "**";
            ConsoleKeyInfo keyinfo;
            while (true)
            {
                keyinfo = Console.ReadKey();
                if (query.Substring(query.Length - 1) == ";" && (keyinfo.Key.Equals(ConsoleKey.Enter)))
                {
                    break;
                }
                else if (keyinfo.Key.Equals(ConsoleKey.Enter))
                {
                    Console.WriteLine();
                    Console.Write("\t>:");
                }
                else
                {
                    query += keyinfo.KeyChar;
                }
            }
            query = query.Remove(0, 2);
            if (query.Equals("exit;"))
            {
                Console.WriteLine("Exiting custom query menu option, printing menu...");
                printMenuReadInput();
            }
            customQuery(query);
        }

    }
    }

