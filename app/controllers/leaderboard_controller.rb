class LeaderboardController < ApplicationController

  # Our logic for the overall leaderboard. This method provides the data for
  # the Top 3 leaderboards and the Personal Achievement leaderboards.
  def index
    @user = session[:user]
   
    session_user_id = @user.id
    # ===> Add something to catch if there isn't a legit user
    #
    @instructorQuery = LeaderboardHelper.user_is_instructor?(session_user_id)
    
    if @instructorQuery
      @course_list = LeaderboardHelper.instructor_courses(session_user_id)
    else
      @course_list = LeaderboardHelper.student_in_which_courses(session_user_id)
    end
    
    @csHash= Leaderboard.getParticipantEntriesInCourses(@course_list, @user.id)
    

    @courseAccomp = Hash.new
    if !@instructorQuery
    
      @courseAccomp = Leaderboard.extractPersonalAchievements(@csHash, @course_list, @user.id)
    else
      @csHash = Leaderboard.sortHash(@csHash)
    end

    
    # Setup top 3 leaderboards for easier consumption by view
    @top3LeaderBoards = Array.new
    
    @csHash.each_pair{|qtype, courseHash|
    
       courseHash.each_pair{|course, userGradeArray|
          courseName = LeaderboardHelper.get_course_name(course)
          achieveName = LeaderboardHelper.get_achieve_name(qtype)
         
         
          leaderboardHash = Hash.new
          leaderboardHash = {:achievement => achieveName,
                             :courseName => courseName,
                             :sortedGrades => userGradeArray}
          

          @top3LeaderBoards << leaderboardHash
       }
    }
    
    
   
    
  

  @top3LeaderBoards.sort!{|x,y| x[:courseName] <=> y[:courseName]}
    # Setup personal achievement leaderboards for easier consumption by view
    @achievementLeaderBoards = Array.new
    if !@instructorQuery
      @courseAccomp.each_pair{ |course, accompHashArray|
         courseAccompListHash = Hash.new      
         courseAccompListHash[:courseName] = LeaderboardHelper.get_course_name(course)
         courseAccompListHash[:accompList] = Array.new
         accompHashArray.each {|accompHash|
            courseAccompListHash[:accompList] << accompHash
         }
         @achievementLeaderBoards << courseAccompListHash
      }  
    end
  end
  

end
