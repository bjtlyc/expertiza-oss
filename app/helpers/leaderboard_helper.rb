  module LeaderboardHelper
  
  # This method gets the name for a course. If the course id
  # provided is 0, that indicates an assignment that is not
  # associated with a course, and the course name provided
  # is "Unaffiliated Assignments"
  def self.get_course_name(course_id)
    if course_id == 0
       course_name = "Unaffiliated Assignments"
    else
       course_name = Course.find(course_id).name
   end
   course_name
  end
    
  # This method converts the questionnaire_type to a
  # sensible string for the Leaderboard table. 
  def self.get_achieve_name(qtype)
    achieve_name = Leaderboard.find(:first , :conditions =>[ "qtype like ?",qtype]).name
    
  end  
  
  # This method gets the name for an assignment. If for some unexpected
  # reason the assignment id does not exist, the string "Unnamed Assignment"
  # is returned.
  def self.get_assignment_name(assignment_id)
    if !assignment_id or assignment_id == 0
      assignment_name = "Unnamed Assignment"
    else
      assignment_name = Assignment.find(assignment_id).name
    end
    assignment_name
  end
  
  # Get the name of the user, honoring the privacy settings.
  # If the requester_id and user_id are the same (the student querying is
  # the person on the leaderboard), a "You!" is displayed.
  # If the requester_id is a TA, instructor, or admin, the privacy
  # setting is disregarded.
  def self.get_user_name(requester_id, user_id)
    user = User.find(user_id)
    instructor = user_is_instructor?(requester_id)
    if user.leaderboard_privacy and requester_id != user_id and !instructor
      user_name = "*****"
    elsif requester_id == user_id
      user_name = "You!"
    else
      user_name = user.fullname
    end
  end
  
  # Identify whether user is considered instructor
  def self.user_is_instructor?(user_id)
    # For now, we'll consider Instructors, Admins, Super-Admins, and TAs as instructors
    instructor_roles = Array.new
    instructor_roles << Role.find_by_name("Instructor").id
    instructor_roles << Role.find_by_name("Administrator").id
    instructor_roles << Role.find_by_name("Super-Administrator").id
    instructor_roles << Role.find_by_name("Teaching Assistant").id
    user = User.find(user_id)
    instructor = false
    if instructor_roles.index(user.role_id)
      instructor = true
    end
    instructor
  end
  
  # Returns list of course ids in which the student has an assignment
  def self.student_in_which_courses(user_id)
    # Get all entries in Participant table for user
    assign_part_list = AssignmentParticipant.find(:all, :conditions =>["user_id =?",user_id])
    @course_list = Array.new
    
    for participant_entry in assign_part_list

## get the ass in quesstion, get the course in question
    assgt = Assignment.find(participant_entry.parent_id)
    if assgt.course_id == nil
        @course_list << 0
      else
       @course_list << assgt.course_id
     end
    end
    
    @course_list.uniq!
  
    @course_list
  end
  
  # This methods gets all the courses that an instructor has been assigned.
  # This method assumes the instructor_id in the Courses table indicates
  # the courses an instructor is managing.
  def self.instructor_courses(user_id)
    course_tuples = Course.find(:all,
                               :conditions => ['instructor_id = ?', user_id])
                               
    @course_list = Array.new
    course_tuples.each { |course| @course_list << course.id }
    @course_list
  end
  
  # This method gets the display data needed to show the Top 3 leaderboard
  def self.get_top3_leaderboards(user_id, assignment_id)
    course_list = LeaderboardHelper.student_in_which_courses(user_id)
    csHash = Leaderboard.getParticipantEntriesInAssignment(assignment_id)
    csHash = Leaderboard.sortHash(csHash)
    
    # Setup top 3 leaderboards for easier consumption by view
    top3_leaderboards = Array.new
    csHash.each_pair{|qtype, course_hash|
       course_hash.each_pair{|course, user_grade_array|
          assignment_name = LeaderboardHelper.get_assignment_name(assignment_id)
          achieve_name = LeaderboardHelper.get_achieve_name(qtype)
          leaderboard_hash = Hash.new
          leaderboard_hash = {:achievement => achieve_name,
                             :courseName => assignment_name,
                             :sortedGrades => user_grade_array}
          top3_leaderboards << leaderboard_hash
       }
    }
    top3_leaderboards
  end
  
  # This method is only provided for diagnostic purposes. It can be executed from
  # script/console to see what's in the Computed Scores table, in case there is
  # a concern about accuracy of leaderboard results.
  def self.dump_cs_table
    @expList = Array.new
    @csEntries = ComputedScore.find(:all)
    @csEntries.each { |cs_entry|
    participant = AssignmentParticipant.find(cs_entry.participant_id)
    questionnaire = Questionnaire.find(cs_entry.questionnaire_id)

       @expList << {:userName => participant.user.name,
                    :assignName => participant.assignment.name,
                    :courseID => participant.assignment.course.id,
                    :instructorName => questionnaire.instructor.name,
                    :qtypeName => questionnaire.qtype,
                    :totalScore => cs_entry.total_score}
    }
    @expList
  end
  
end
