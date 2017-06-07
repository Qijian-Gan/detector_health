package IENReaderByJava;

// Import functions
import java.io.*;
import java.util.*;


public class Main {

    public Main(){
    }

    public List readIENData(String IENDataFileName){

        List<List<String>> arr = new ArrayList<List<String>>();
        List<String> listDevInv = new ArrayList<String>();
        List<String> listDevData = new ArrayList<String>();
        List<String> listIntSigInv = new ArrayList<String>();
        List<String> listIntSigData = new ArrayList<String>();
        List<String> listPlanPhase = new ArrayList<String>();
        List<String> listLastCyclePhase = new ArrayList<String>();

        String tmpDevInvString;
        String tmpDevDataString;
        String tmpIntSigInvString;
        String tmpIntSigDataString;
        String tmpPlanPhaseString;
        String tmpLastCyclePhaseString;

        // Open a new file
        File ienFile = new File(IENDataFileName);

        // Check the existence of the file
        if(!ienFile.exists())
        {
            System.out.println("Can not find the file!");
            return null;
        }

        // If the file exists, do the following steps
        try {
            FileReader frIEN = new FileReader(ienFile);
            BufferedReader brIEN = new BufferedReader(frIEN);

            String text = null;
            String [] tmpArray;
            String [] tmpDateTime;
            String [] tmpPhase;
            String [] tmpArrayWithoutSpace;
            int j;
            while ((text = brIEN.readLine())!=null) {

                tmpArray=text.split(","); // Split strings

                //***********First: If it is for device inventory**************
                if(tmpArray[0].equals("Device Inventory list")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        //Get the date and time
                        tmpArray=text.split(",");
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpDevInvString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]+","+tmpDateTime[2];
                        if(tmpArray.length==11){
                            tmpDevInvString= tmpDevInvString+","+tmpArray[3]+","+tmpArray[4]+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10];
                        }
                        else if(tmpArray.length==12){
                            String tmp=tmpArray[3]+"&"+tmpArray[4];
                            tmpDevInvString= tmpDevInvString+","+tmp+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10]+","+tmpArray[11];
                        }else if(tmpArray.length==13){
                            String tmp=tmpArray[3]+"&"+tmpArray[4]+"&"+tmpArray[5];
                            tmpDevInvString= tmpDevInvString+","+tmp+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10]+","+tmpArray[11]+","+tmpArray[12];
                        }else{
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        listDevInv.add(tmpDevInvString);
                    }
                }

                //***********Second: If it is for device data**************
                if(tmpArray[0].equals("Device Data")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        tmpArray=text.split(",");
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpDevDataString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]+","+tmpDateTime[2];
                        if(tmpArray.length==10){
                            tmpDevDataString= tmpDevDataString+","+tmpArray[3]+","+tmpArray[4]+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9];
                        }
                        else if(tmpArray.length==11){
                            String tmp=tmpArray[3]+"&"+tmpArray[4];
                            tmpDevDataString= tmpDevDataString+","+tmp+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10];
                        }else if(tmpArray.length==12){
                            String tmp=tmpArray[3]+"&"+tmpArray[4]+"&"+tmpArray[5];
                            tmpDevDataString= tmpDevDataString+","+tmp+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10]+","+tmpArray[11];
                        }else{
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        listDevData.add(tmpDevDataString);
                    }
                }

                //***********Third: If it is for intersection signal inventory**************
                if(tmpArray[0].equals("Intersection Signal Inventory list")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        tmpArray=text.split(",");
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpIntSigInvString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]+","+tmpDateTime[2];
                        if(tmpArray.length==9){
                            tmpIntSigInvString= tmpIntSigInvString+","+tmpArray[3]+","+tmpArray[4]+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8];
                        }
                        else if(tmpArray.length==10){
                            String tmp=tmpArray[3]+"&"+tmpArray[4];
                            tmpIntSigInvString= tmpIntSigInvString+","+tmp+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9];
                        }else if(tmpArray.length==11){
                            String tmp=tmpArray[3]+"&"+tmpArray[4]+"&"+tmpArray[5];
                            tmpIntSigInvString= tmpIntSigInvString+","+tmp+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9]+","+tmpArray[10];
                        }else{
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        listIntSigInv.add(tmpIntSigInvString);
                    }
                }

                //***********Fourth: If it is for intersection signal data*************
                if(tmpArray[0].equals("Intersection Signal Data")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        tmpArray=text.split(",");
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpIntSigDataString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]+","+tmpDateTime[2];
                        if(tmpArray.length==10){
                            tmpIntSigDataString= tmpIntSigDataString+","+tmpArray[3]+","+tmpArray[4]+","+tmpArray[5]+","+tmpArray[6]
                                    +","+tmpArray[7]+","+tmpArray[8]+","+tmpArray[9];
                        }else{
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        listIntSigData.add(tmpIntSigDataString);
                    }
                }

                //***********Fifth: If it is for intersection planned phases *************
                if(tmpArray[0].equals("Intersection Signal Planned Phases")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        tmpArray=text.split(",");
                        if(tmpArray.length!=4){
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpPhase =(tmpArray[3]).split("\\[");
                        tmpPhase =(tmpPhase[1]).split("]");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpPlanPhaseString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]+","+tmpDateTime[2]+","+tmpPhase[0];
                        listPlanPhase.add(tmpPlanPhaseString);
                    }
                }

                //***********Sixth: If it is for intersection last-cycle phases *************
                if(tmpArray[0].equals("Intersection Signal Last Cycle Phases")) {

                    //Ignore the first line
                    brIEN.readLine();
                    while((text = brIEN.readLine()) != null && text.length()!=0) {
                        tmpArray=text.split(",");
                        if(tmpArray.length!=5){
                            System.out.println("Wrong input string type!");
                            return null;
                        }
                        tmpDateTime = (tmpArray[2]).split(" ");
                        tmpPhase =(tmpArray[4]).split("\\[");
                        tmpPhase =(tmpPhase[1]).split("]");
                        tmpArray[2]=tmpArray[2].replace(" ","/");

                        tmpLastCyclePhaseString=tmpArray[0]+","+tmpArray[1]+","+tmpArray[2]+","+tmpDateTime[1]
                                +","+tmpDateTime[2]+","+tmpArray[3]+","+tmpPhase[0];
                        listLastCyclePhase.add(tmpLastCyclePhaseString);
                    }
                }
            }
            brIEN.close();
        }catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }

        arr.add(listDevInv);
        arr.add(listDevData);
        arr.add(listIntSigInv);
        arr.add(listIntSigData);
        arr.add(listPlanPhase);
        arr.add(listLastCyclePhase);
        return arr;
    }

    public List redIENConnectionDataStatus(String IENDataFileName){

        List<String> listIENStatus = new ArrayList<String>();

        // Open a new file
        File ienFile = new File(IENDataFileName);

        // Check the existence of the file
        if(!ienFile.exists())
        {
            System.out.println("Can not find the file!");
            return null;
        }

        // If the file exists, do the following steps
        try {
            FileReader frIEN = new FileReader(ienFile);
            BufferedReader brIEN = new BufferedReader(frIEN);

            String text = null;
            String [] tmpArray;

            // Ignore the first two lines
            text = brIEN.readLine();
            text = brIEN.readLine();

            // Starting from the third line
            while ((text = brIEN.readLine())!=null) {

                tmpArray=text.split(","); // Split strings

                String tmpDate=tmpArray[0];
                String tmpTime=tmpArray[1];

                int totSum=
                        Integer.parseInt(tmpArray[3])+ Integer.parseInt(tmpArray[27])+
                        Integer.parseInt(tmpArray[6])+ Integer.parseInt(tmpArray[30])+
                        Integer.parseInt(tmpArray[9])+ Integer.parseInt(tmpArray[33])+
                        Integer.parseInt(tmpArray[12])+Integer.parseInt(tmpArray[36])+
                        Integer.parseInt(tmpArray[15])+Integer.parseInt(tmpArray[39])+
                        Integer.parseInt(tmpArray[18])+Integer.parseInt(tmpArray[42])+
                        Integer.parseInt(tmpArray[21])+Integer.parseInt(tmpArray[45])+
                        Integer.parseInt(tmpArray[24])+Integer.parseInt(tmpArray[48]);
                String StatusIEN="0";
                if(totSum>=1){
                    StatusIEN="1";
                }
                String StatusLACO="0";
                if(Integer.parseInt(tmpArray[45])==1){
                    StatusLACO="1";
                }
                String totLACODetector=tmpArray[46];

                listIENStatus.add(tmpDate+","+tmpTime+","+StatusIEN+","+StatusLACO+","+totLACODetector);
            }
            brIEN.close();
        }catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return listIENStatus;
    }
}
