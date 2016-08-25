/*
    Copyright (c) 2016, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2016
* @group CourseEnrollments
* @group-content ../../ApexDocContent/CourseEnrollments.htm
* @description Tests specific to Course Connections Backfill
*/
@isTest
public with sharing class CCON_ConnectionBackfill_TEST {

    private static Account university;
    private static Account biologyDept;
    private static Account psychologyDept;
    private static Course__c biologyCourse;
    private static Course__c psychologyCourse;
    private static Term__c term;
    private static List<Course_Offering__c> offeringsList;
    private static List<Contact> facultyContacts;
    private static List<Contact> studentContacts;
    private static List<Course_Enrollment__c> studentConnections;

    private static void setup() {

        // Create university
        university = new Account(Name = 'Advanced University');
        insert university;

        // Create Biology department
        biologyDept = new Account(Name = 'Biology Department', Parent = university);

        // Create Psychology department
        psychologyDept = new Account(Name = 'Psychology Department', Parent = university);

        insert new List<Account>{
            biologyDept,
            psychologyDept
        };

        // Create Term
        term = new Term__c(Account__c = university.Id, Start_Date__c = System.today() + 5, End_Date__c = System.today() + 90);

        // Create Biology Course
        biologyCourse = new Course__c(Course_ID__c = 'Biology 101', Account__c = biologyDept.Id, Credit_Hours__c = 40,
           Description__c = 'Biology 101');

        // Create Psychology Course
        psychologyCourse = new Course__c(Course_ID__c = 'Psychology 101', Account__c = psychologyDept.Id, Credit_Hours__c = 40,
           Description__c = 'Psychology 101');

        insert new List<SObject>{
            term,
            biologyCourse,
            psychologyCourse
        };

        facultyContacts = new List<Contact>();
        facultyContacts = createContacts(20, 'faculty');
        insert facultyContacts;

        studentContacts = new List<Contact>();
        studentContacts = createContacts(20, 'student');
        insert studentContacts;

        // Create Biology Offerings and Psychology Offerings
        offeringsList = new List<Course_Offering__c>();
        offeringsList.addAll(createCourseOfferings(biologyCourse.Id, term.Id, facultyContacts));
        offeringsList.addAll(createCourseOfferings(psychologyCourse.Id, term.Id, facultyContacts));
        insert offeringsList;

        studentConnections = new List<Course_Enrollment__c>();
        createCourseConnections(studentContacts);
        insert studentConnections;

        // Enable Course Connections
        UTIL_CustomSettingsFacade.getSettingsForTests(
            new Hierarchy_Settings__c(
                Enable_Course_Connections__c = true,
                Default_Faculty_RecordType_Id__c = UTIL_CustomSettingsFacade.getFacultyConnectionRecTypeID(),
                Default_Enrolled_Student_RecordType_Id__c = UTIL_CustomSettingsFacade.getStudentConnectionRecTypeID()
            )
        );
    }

    @isTest
    public static void offeringsCreated() {
        setup();

        List<Course_Enrollment__c> conns = [SELECT Id FROM Course_Enrollment__c];
        System.assertEquals(840, conns.size());

        //run batch
        Test.StartTest();
        CCON_ConnectionBackfill_BATCH batch = new CCON_ConnectionBackfill_BATCH();
        ID ApexJobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        conns = [SELECT Id FROM Course_Enrollment__c];
        System.assertEquals(840, conns.size());

    }

    private static List<Contact> createContacts(Integer amount, String uniqueString) {
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < amount; i++) {
            contacts.add(new Contact(
                FirstName = 'backfill',
                LastName = 'test contact ' + i + uniqueString
            ));
        }
        return contacts;
    }

    private static List<Course_Offering__c> createCourseOfferings(Id courseId, Id termId, List<Contact> faculty) {
        List<Course_Offering__c> offerings = new List<Course_Offering__c>();
        for(Integer i = 0; i < faculty.size(); i++) {
            offerings.add(new Course_Offering__c(
                Section_ID__c = 'course' + courseId + termId + i,
                Course__c = courseId,
                Term__c = termId,
                Capacity__c = 200,
                Faculty__c = faculty[i].Id)
            );
        }
        return offerings;
    }

    private static void createCourseConnections(List<Contact> students) {
        for(Course_Offering__c offering : offeringsList){
            for(Contact student : students){
                // Create another Course Connection
                studentConnections.add(new Course_Enrollment__c(
                    Contact__c = student.Id,
                    Course_Offering__c = offering.Id
                ));
            }
        }
    }
}