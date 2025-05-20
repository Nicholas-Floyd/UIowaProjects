from flask import Flask, render_template, request, redirect, url_for, flash, session, jsonify
import uuid
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
import os
from dotenv import load_dotenv
from datetime import timedelta


load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY")

app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")  
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SESSION_PERMANENT"] = False

db = SQLAlchemy(app)

@app.route("/")
def home():
    if "userID" not in session:
        return redirect(url_for("login"))
    return render_template("home.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        try:
            stmt = text("CALL VerifyUserLogin(:username)")
            result = db.session.execute(stmt, {"username": username}).fetchone()
            db.session.commit()

            if result:
                userID, db_username, db_hash, role_name, first_name, last_name = result

                if check_password_hash(db_hash, password):
                    session["userID"] = userID
                    session["username"] = db_username
                    session["role"] = role_name
                    session["first_name"] = first_name
                    session["last_name"] = last_name
                    session["name"] = f"{first_name} {last_name}"

                    flash("Login successful!", "success")

                    if role_name == "Physician":
                        incomplete_physician = db.session.execute(text(""" SELECT COUNT(*) FROM Physician
                            WHERE UserID = :userID AND (PhysicianType IS NULL OR PhysicianRankID IS NULL) """), {"userID": userID}).scalar()

                        incomplete_departments = db.session.execute(text(""" SELECT COUNT(*) FROM Physician p LEFT JOIN PhysicianDepartment pd ON p.PhysicianID = pd.PhysicianID
                            WHERE p.UserID = :userID AND pd.DeptID IS NULL """), {"userID": userID}).scalar()

                        missing_specialization = db.session.execute(text(""" SELECT COUNT(*) FROM Physician p LEFT JOIN PhysicianSpecializations ps ON p.PhysicianID = ps.PhysicianID
                            WHERE p.UserID = :userID AND ps.SpecializationID IS NULL """), {"userID": userID}).scalar()

                        db.session.commit()

                        if incomplete_physician or incomplete_departments or missing_specialization:
                            flash("Please complete your physician profile.", "info")
                            return redirect(url_for("complete_physician_profile"))

                        return redirect(url_for("physician_dashboard"))

                    elif role_name == "Nurse":
                        incomplete = db.session.execute(text("""SELECT COUNT(*) FROM NurseDepartment nd
                            JOIN Nurse n ON nd.NurseID = n.NurseID WHERE n.UserID = :userID """), {"userID": userID}).scalar()

                        if incomplete == 0:
                            flash("Please complete your nurse profile.", "info")
                            return redirect(url_for("complete_nurse_profile"))
                        return redirect(url_for("nurse_dashboard"))

                    elif role_name == "Admin":
                        return redirect(url_for("admin_dashboard"))

                    else:
                        return redirect(url_for("home"))

                else:
                    flash("Incorrect password.", "danger")
            else:
                flash("Username not found.", "danger")

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("login.html")

@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for("login"))

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        try:
            username = request.form["username"]
            stmt_check = text("CALL CheckUsernameExists(:username)")
            result = db.session.execute(stmt_check, {"username": username}).fetchone()
            db.session.commit()

            if result and result[0] > 0:
                flash("Username already exists. Please choose a different one.", "danger")
                return render_template("signup.html")

            userID = str(uuid.uuid4())
            first_name = request.form["first_name"]
            last_name = request.form["last_name"]
            email = request.form["email"]
            password = request.form["password"]
            phone = request.form["phone"]
            gender = request.form["gender"]
            sex = request.form["sex"]
            dob = request.form["dob"]
            hashed_pw = generate_password_hash(password)

            stmt = text(""" CALL AddUserProfile( :userID, :username, :first_name, :last_name,
                    :email, :password_hash, :roleID, :phone, :gender, :sex, :dob) """)

            db.session.execute(stmt, {"userID": userID, "username": username, "first_name": first_name,
                "last_name": last_name, "email": email, "password_hash": hashed_pw, "roleID": "R1",
                "phone": phone, "gender": gender, "sex": sex, "dob": dob })

            db.session.commit()
            flash("Signup successful!", "success")
            return redirect(url_for("login"))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("signup.html")

@app.route("/change_password", methods=["GET", "POST"])
def change_password():
    if "userID" not in session:
        flash("You must be logged in to change your password.", "danger")
        return redirect(url_for("login"))

    if request.method == "POST":
        old_password = request.form["old_password"]
        new_password = request.form["new_password"]
        confirm_password = request.form["confirm_password"]

        if new_password != confirm_password:
            flash("New passwords do not match.", "danger")
            return redirect(url_for("change_password"))

        try:
            # Get current hash from the database
            result = db.session.execute(
                text("CALL VerifyUserLogin(:username)"),
                {"username": session["username"]}
            ).fetchone()
            db.session.commit()

            if result:
                userID, db_username, db_hash, _, _, _ = result

                if not check_password_hash(db_hash, old_password):
                    flash("Old password is incorrect.", "danger")
                    return redirect(url_for("change_password"))

                # Hash the new password
                new_hash = generate_password_hash(new_password)

                # Update the password
                db.session.execute(
                    text("CALL ChangeUserPassword(:userID, :newHash)"),
                    {"userID": session["userID"], "newHash": new_hash}
                )
                db.session.commit()

                flash("Password updated successfully!", "success")
                return redirect(url_for("home"))

            else:
                flash("User record not found.", "danger")

        except Exception as e:
            db.session.rollback()
            flash(f"Error updating password: {str(e)}", "danger")

    return render_template("change_password.html")


@app.route("/admin_dashboard", methods=["GET", "POST"])
def admin_dashboard():
    if "userID" not in session or session.get("role") != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    
    try:
        stmt = text("CALL GetAllUsers()")
        users = db.session.execute(stmt).fetchall()
         




        #retrieve all SOAP summaries
        stmt = text("""
            SELECT 
    s.SummaryID, 
    u.FirstName, 
    u.LastName, 
    sub.CC, 
    sub.HPI, 
    vit.BloodPressure AS BP, 
    vit.HeartRate AS HR, 
    vit.Temp, 
    ass.Assessment AS Diagnosis, 
    pl.PlanStatus AS Status,  
    pl.Notes AS PlanNotes
FROM AfterVisitSummary s
LEFT JOIN Patient p ON s.PatientID = p.PatientID
LEFT JOIN User u ON p.UserID = u.UserID  
LEFT JOIN SubjectiveData sub ON s.SummaryID = sub.SummaryID
LEFT JOIN ObjectiveData obj ON s.SummaryID = obj.SummaryID
LEFT JOIN Vitals vit ON obj.ObjectiveDataID = vit.ObjectiveDataID  
LEFT JOIN Assessment ass ON s.SummaryID = ass.SummaryID
LEFT JOIN Plan pl ON s.SummaryID = pl.SummaryID
                    WHERE s.SummaryID = 'SUM004' -- testing...
        """)
        summaries = db.session.execute(stmt).fetchall()
        print("Summaries:", summaries)
        
        db.session.commit()






    except Exception as e:
        db.session.rollback()
        flash(f"Error loading users: {str(e)}", "danger")
        users = []
    return render_template("admin_dashboard.html", users=users)

@app.route("/physician_dashboard", methods=["GET", "POST"])
def physician_dashboard():
    if "userID" not in session or session.get("role") != "Physician":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    return render_template("physician_dashboard.html")

@app.route("/nurse_dashboard")
def nurse_dashboard():
    if "userID" not in session or session.get("role") != "Nurse":
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))

    nurse_row = db.session.execute( text("CALL GetNurseIDByUserID(:userID)"), {"userID": session["userID"]}).fetchone()

    if not nurse_row:
        flash("Nurse profile not found.", "danger")
        return redirect(url_for("home"))

    nurseID = nurse_row[0]
    assigned_departments = db.session.execute(text("CALL GetDepartmentsByNurseID(:nurseID)"),{"nurseID": nurseID}).fetchall()
    db.session.commit()

    return render_template("nurse_dashboard.html",assigned_departments=assigned_departments)

@app.route("/admin/create_user", methods=["GET", "POST"])
def create_user():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))

    if request.method == "POST":
        try:
            userID = str(uuid.uuid4())
            username = request.form["username"]
            first_name = request.form["first_name"]
            last_name = request.form["last_name"]
            email = request.form["email"]
            password = request.form["password"]
            phone = request.form["phone"]
            gender = request.form["gender"]
            sex = request.form["sex"]
            dob = request.form["dob"]
            selected_role = request.form["roleID"]  
            hashed_pw = generate_password_hash(password)

            stmt = text(""" CALL AddUserProfile( :userID, :username, :first_name, :last_name,
                    :email, :password_hash, :roleID, :phone, :gender, :sex, :dob)""")

            db.session.execute(stmt, {"userID": userID,"username": username,"first_name": first_name,
                "last_name": last_name,"email": email,"password_hash": hashed_pw,"roleID": selected_role,  
                "phone": phone,"gender": gender,"sex": sex,"dob": dob})

            db.session.commit()
            return redirect(url_for("admin_dashboard"))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("create_user.html")

@app.route("/complete_physician_profile", methods=["GET", "POST"])
def complete_physician_profile():
    if "userID" not in session or session.get("role") != "Physician":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    if request.method == "POST":
        try:
            DeptIDs = request.form.getlist("DeptIDs")
            specializationID = request.form["specializationID"]
            physician_type = request.form["physician_type"]
            rankID = request.form["rankID"]

            # === Fetch PhysicianID directly ===
            result = db.session.execute(
                text("SELECT PhysicianID FROM Physician WHERE UserID = :userID"),
                {"userID": session["userID"]}
            ).fetchone()
            db.session.commit()

            if not result or not result[0]:
                flash("No Physician profile found for your user account. Please contact admin.", "danger")
                print(f"[DEBUG] No Physician profile found for userID {session['userID']}")
                return redirect(url_for("complete_physician_profile"))

            physician_id = result[0]
            print(f"[DEBUG] Submitting profile update for PhysicianID: {physician_id}")
            print(f"[DEBUG] DeptIDs: {DeptIDs}, SpecializationID: {specializationID}, Type: {physician_type}, RankID: {rankID}")

            # === Call new stored procedure using PhysicianID ===
            db.session.execute(text("CALL CompletePhysicianProfileByID(:physicianID, :dept_json, :type, :rank, :spec)"), {
                "physicianID": physician_id,
                "dept_json": str(DeptIDs).replace("'", '"'),
                "type": physician_type,
                "rank": rankID,
                "spec": specializationID
            })

            db.session.commit()
            flash("Profile updated successfully!", "success")
            return redirect(url_for("physician_dashboard"))

        except Exception as e:
            db.session.rollback()
            flash(f"Error updating profile: {str(e)}", "danger")
            print(f"[ERROR] Exception while updating profile: {str(e)}")

    # === Load dropdown data ===
    departments = db.session.execute(text("SELECT DeptID, DeptName FROM Department")).fetchall()
    specializations = db.session.execute(text("SELECT SpecializationID, Specialization FROM Specializations")).fetchall()
    ranks = db.session.execute(text("SELECT RankID, RankName FROM PhysicianRanks")).fetchall()
    db.session.commit()

    return render_template(
        "complete_physician_profile.html",
        departments=departments,
        specializations=specializations,
        ranks=ranks
    )

@app.route("/appointments", methods=["GET", "POST"])
def appointments():
    if "userID" not in session or session.get("role") != "Patient":
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))

    mode = request.args.get('mode', 'upcoming')

    try:
        patientID = db.session.execute(
            text("""SELECT PatientID FROM Patient WHERE UserID = :userID"""),
            {"userID": session["userID"]}
        ).scalar()

        if request.method == "POST":
            try:
                # Collect form data including DeptID
                dept_id = request.form["DeptID"]
                slot_id = request.form["slotID"]
                physician_id = request.form["physicianID"]
                type_id = request.form["typeID"]

                # Call updated stored procedure
                db.session.execute(text("""
                    CALL ScheduleAppointmentForPatient(:userID, :slotID, :physicianID, :typeID, :deptID)
                """), {
                    "userID": session["userID"],
                    "slotID": slot_id,
                    "physicianID": physician_id,
                    "typeID": type_id,
                    "deptID": dept_id
                })
                db.session.commit()
                flash("Appointment scheduled successfully!", "success")
                return redirect(url_for("appointments"))

            except Exception as e:
                db.session.rollback()
                flash(f"Error scheduling appointment: {str(e)}", "danger")

        # Load appointment list
        appointments = db.session.execute(
            text("""CALL GetPatientAppointments(:patientID, :mode)"""),
            {"patientID": patientID, "mode": mode}
        ).fetchall()

        # Load dropdowns
        departments = db.session.execute(text("SELECT DeptID, DeptName FROM Department")).fetchall()
        types = db.session.execute(text("SELECT TypeID, TypeName FROM AppointmentTypes")).fetchall()
        db.session.commit()

        return render_template(
            "appointments.html",
            appointments=appointments,
            departments=departments,
            types=types,
            mode=mode
        )

    except Exception as e:
        db.session.rollback()
        flash(f"Unexpected error: {str(e)}", "danger")
        return redirect(url_for("home"))

@app.route("/physician_appointments", methods=["GET", "POST"])
def physician_appointments():
    if session.get("role") != "Physician":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    userID = session["userID"]
    mode = request.args.get('mode', 'upcoming')

    try:
        physicianID = db.session.execute(text(""" SELECT PhysicianID FROM Physician WHERE UserID = :userID """), {"userID": userID}).scalar()

        if not physicianID:
            flash("Physician profile not found.", "danger")
            return redirect(url_for("login"))

        if request.method == "POST":
            try:
                db.session.execute(text(""" CALL AddTimeSlot(:slotID, :deptID, :physicianID, :start_time, :end_time) """), {
                    "slotID": str(uuid.uuid4()), "deptID": request.form["DeptID"], "physicianID": physicianID,
                    "start_time": request.form["start_time"], "end_time": request.form["end_time"] })
                db.session.commit()
                return redirect(url_for("physician_appointments"))
            except Exception as e:
                db.session.rollback()
                flash(f"Error creating slot: {str(e)}", "danger")

        appointments = db.session.execute(text(""" CALL GetPhysicianAppointments(:physicianID, :mode)
        """), {"physicianID": physicianID, "mode": mode}).fetchall()

        departments = db.session.execute(text(""" CALL GetDepartmentsForPhysician(:userID) """), {"userID": userID}).fetchall()

        db.session.commit()
        return render_template("physician_appointments.html", appointments=appointments, departments=departments, mode=mode)

    except Exception as e:
        db.session.rollback()
        flash(f"Unexpected error: {str(e)}", "danger")
        return redirect(url_for("login"))

@app.route("/get_physicians/<DeptID>")
def get_physicians(DeptID):
    result = db.session.execute(text("""
        CALL GetPhysiciansByDepartment(:DeptID) """), {"DeptID": DeptID}).fetchall()
    db.session.commit()
    physicians = [{"PhysicianID": row.PhysicianID, "FirstName": row.FirstName, "LastName": row.LastName} for row in result]
    return jsonify(physicians)  


@app.route("/get_slots/<physicianID>")
def get_slots(physicianID):
    result = db.session.execute(text("""
        CALL GetAvailableSlotsByPhysician(:physicianID)
    """), {"physicianID": physicianID}).fetchall()
    db.session.commit()

    slots = [{"SlotID": row.SlotID, "StartTime": row.StartTime, "EndTime": row.EndTime} for row in result]
    return jsonify(slots)  


@app.route("/cancel_appointment/<apptID>", methods=["POST"])
def cancel_appointment(apptID):
    if "userID" not in session or session.get("role") not in ("Patient", "Physician", "Admin"):
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))

    try:
        db.session.execute(text("CALL CancelAppointment(:apptID)"), {"apptID": apptID})
        db.session.commit()

        if session["role"] == "Patient": return redirect(url_for("appointments"))
        elif session["role"] == "Physician": return redirect(url_for("physician_appointments"))
        else: return redirect(url_for("admin_view_appointments"))
    except Exception as e:
        db.session.rollback()
        flash(f"Error cancelling appointment: {str(e)}", "danger")

        return redirect(url_for("home"))

@app.route("/reschedule_appointment/<apptID>", methods=["GET", "POST"])
def reschedule_appointment(apptID):
    if "userID" not in session:
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))
    try:
        appt = db.session.execute(text(""" CALL GetAppointmentDetails(:apptID) """), {"apptID": apptID}).fetchone()
        if not appt:
            flash("Appointment not found.", "danger")
            return redirect(url_for("appointments"))

        departments = db.session.execute(text("CALL GetAllDepartments()")).fetchall()
        selected_DeptID = appt.DeptID 

    except Exception as e:
        db.session.rollback()
        flash(f"Error loading appointment: {str(e)}", "danger")
        return redirect(url_for("appointments"))

    if request.method == "POST":
        new_slotID = request.form["slotID"]
        new_physicianID = request.form["physicianID"]
        new_DeptID = request.form["DeptID"]

        try:
            db.session.execute(text(""" CALL RescheduleAppointment(:apptID, :new_slotID, :new_physicianID, :new_DeptID) """), {
                "apptID": apptID, "new_slotID": new_slotID, "new_physicianID": new_physicianID, "new_DeptID": new_DeptID })
            db.session.commit()
            if session.get("role") == "Patient": return redirect(url_for('appointments'))
            elif session.get("role") == "Physician": return redirect(url_for('physician_appointments'))
            elif session.get("role") == "Admin": return redirect(url_for('admin_view_appointments'))
            else: return redirect(url_for('home'))

        except Exception as e:
            db.session.rollback()
            flash(f"Error during rescheduling: {str(e)}", "danger") 

    return render_template("reschedule_appointment.html", appt=appt, departments=departments, selected_DeptID=selected_DeptID)

@app.route("/complete_nurse_profile", methods=["GET", "POST"])
def complete_nurse_profile():
    print("User ID in session:", session.get("userID"))
    if "userID" not in session or session.get("role") != "Nurse":
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))

    try:
        nurse_row = db.session.execute(text("CALL GetNurseIDByUserID(:userID)"),{"userID": session["userID"]}).fetchone()
        print("nurse_row in complete_nurse_profile:", nurse_row)
        if not nurse_row:
            flash("Nurse profile not found.", "danger")
            return redirect(url_for("home"))

        nurseID = nurse_row[0]
        if request.method == "POST":
            DeptIDs = request.form.getlist("DeptIDs")
            db.session.execute(text("DELETE FROM NurseDepartment WHERE NurseID = :nurseID"), {"nurseID": nurseID})

            for DeptID in DeptIDs:
                db.session.execute(text("CALL InsertNurseDepartment(:nurseID, :DeptID)"), { "nurseID": nurseID, "DeptID": DeptID })

            db.session.commit()
            return redirect(url_for("nurse_dashboard"))

        departments = db.session.execute(text("SELECT DeptID, DeptName FROM Department")).fetchall()
        assigned_rows = db.session.execute(text("CALL GetDepartmentsByNurseID(:nurseID)" ), {"nurseID": nurseID}).fetchall()
        assigned_departments = {row.DeptID for row in assigned_rows}
        db.session.commit()
        return render_template( "complete_nurse_profile.html", departments=departments,assigned_departments=assigned_departments)
    
    except Exception as e:
        db.session.rollback()
        flash(f"Error loading profile: {str(e)}", "danger")
        return redirect(url_for("home"))
    
@app.route("/admin/view_appointments")
def admin_view_appointments():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    try:
        appointments = db.session.execute(text("CALL GetAllAppointments()")).fetchall()
        patients = db.session.execute(text("CALL GetAllPatients()")).fetchall()
        departments = db.session.execute(text("CALL GetAllDepartments()")).fetchall()
        types = db.session.execute(text("SELECT TypeID, TypeName FROM AppointmentTypes")).fetchall()
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        flash(f"Error loading appointments: {str(e)}", "danger")
        appointments, patients, departments, types = [], [], [], []
    return render_template("admin_view_appointments.html", appointments=appointments, patients=patients, departments=departments, types=types)

@app.route("/admin/manage_clinics", methods=["GET", "POST"])
def admin_manage_clinics():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "add":
                clinicID = str(uuid.uuid4())
                name = request.form.get("ClinicName")
                db.session.execute(text("CALL AddClinic(:ID, :name)"), { "ID": clinicID, "name": name })
            elif action == "edit":
                db.session.execute(text("CALL EditClinic(:clinicID, :new_name)"), { "clinicID": request.form.get("clinicID"), "new_name": request.form.get("new_ClinicName") })
            elif action == "remove_clinic_dept":
                db.session.execute(text("CALL RemoveDepartmentFromClinic(:clinicID, :DeptID)"), {
                    "clinicID": request.form.get("clinicID"), "DeptID": request.form.get("DeptID") })
            db.session.commit()

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")
    try:
        clinics = db.session.execute(text("CALL GetAllClinics()")).mappings().all()
        clinic_links = db.session.execute(text("CALL GetClinicDepartmentLinks()")).fetchall()
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        flash(f"Error loading clinics: {str(e)}", "danger")
        clinics = []
        clinic_links = []
    return render_template("admin_manage_clinics.html", clinics=clinics, clinic_links=clinic_links)

@app.route("/admin_manage_departments", methods=["GET", "POST"])
def admin_manage_departments():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access.", "danger")
        return redirect(url_for("login"))
    if request.method == "POST":
        action = request.form.get("action")
        if action == "add":
            try:
                DeptID = str(uuid.uuid4())
                deptName = request.form["deptName"]
                clinicIDs = request.form.getlist("clinicIDs")

                # STEP 1: Insert department once
                db.session.execute(text("INSERT INTO Department (DeptID, DeptName) VALUES (:ID, :name)"), {
                    "ID": DeptID, "name": deptName })

                # STEP 2: Link to multiple clinics
                for clinicID in clinicIDs:
                    db.session.execute(text("INSERT INTO ClinicDepartment (DeptID, ClinicID) VALUES (:DeptID, :clinicID)"), {
                        "DeptID": DeptID, "clinicID": clinicID })

                db.session.commit()
            except Exception as e:
                db.session.rollback()
                flash(f"Error adding department: {str(e)}", "danger")

        elif action == "edit":
            try:
                DeptID = request.form["DeptID"]
                new_name = request.form["new_deptName"]
                db.session.execute(text("CALL EditDepartment(:DeptID, :new_name)"), { "DeptID": DeptID,"new_name": new_name})
                db.session.commit()
            except Exception as e:
                db.session.rollback()
                flash(f"Error editing department: {str(e)}", "danger")

    departments = db.session.execute(text("CALL GetAllDepartments()")).fetchall()
    clinics = db.session.execute(text("CALL GetAllClinics()")).mappings().all()
    db.session.commit()
    return render_template("admin_manage_departments.html", departments=departments, clinics=clinics)

@app.route("/admin_manage_specializations", methods=["GET", "POST"])
def admin_manage_specializations():
    if session.get("role") != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    if request.method == "POST":
        action = request.form.get("action")
        try:
            if action == "add":
                db.session.execute(
                    text("CALL AddSpecialization(:ID, :name)"),
                    {"ID": str(uuid.uuid4()), "name": request.form["specialization"]}
                )
            elif action == "remove_spec":
                db.session.execute(
                    text("CALL RemoveSpecializationFromUser(:username, :specID)"),{"username": request.form["username"],"specID": request.form["specID"]})
            elif action == "edit":
                db.session.execute(
                    text("CALL EditSpecialization(:specID, :new_name)"),{ "specID": request.form["specID"],"new_name": request.form["new_spec_name"] })
            elif action == "assign_multiple":
                username = request.form["username"]
                specIDs = request.form.getlist("specializationIDs")
                if not specIDs:
                    flash("No specializations selected.", "warning")
                else:
                    for specID in specIDs:
                        db.session.execute(
                            text("CALL AssignSpecializationByRole(:username, :specID)"), {"username": username, "specID": specID})
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            flash(f"Error processing action: {str(e)}", "danger")
    user_specializations = db.session.execute(text("CALL GetUsersWithSpecializations()")).fetchall()
    user_specializations_rows = db.session.execute(text("CALL GetUsersSpecializationRows()")).fetchall()
    specs = db.session.execute(text("CALL GetAllSpecializations()")).fetchall()
    db.session.commit()
    return render_template("admin_manage_specializations.html",specializations=specs,user_specs=user_specializations,user_specs_rows=user_specializations_rows)


@app.route("/admin/schedule_appointment", methods=["POST"])
def admin_schedule_appointment():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))
    try:
        userID = request.form["userID"]
        slot_id = request.form["slotID"]
        physician_id = request.form["physicianID"]
        dept_id = request.form["DeptID"]
        type_id = request.form["typeID"]  # <-- now pulled from form

        db.session.execute(text("""
            CALL ScheduleAppointmentForPatient(:userID, :slotID, :physicianID, :typeID, :deptID)
        """), {
            "userID": userID,
            "slotID": slot_id,
            "physicianID": physician_id,
            "typeID": type_id,
            "deptID": dept_id
        })
        db.session.commit()
        flash("Appointment scheduled successfully!", "success")
    except Exception as e:
        db.session.rollback()
        flash(f"Error scheduling appointment: {str(e)}", "danger")
    return redirect(url_for("admin_view_appointments"))

@app.route("/api/get_slots_by_department/<DeptID>")
def get_slots_by_department(DeptID):
    try:
        result = db.session.execute(text("CALL GetAvailableSlotsByDepartment(:DeptID)"), {"DeptID": DeptID}).mappings().all()
        return jsonify([dict(row) for row in result])
    except Exception:
        db.session.rollback()
        return jsonify([]), 500

@app.route("/edit_profile", methods=["GET", "POST"])
def edit_profile():
    if "userID" not in session:
        flash("Please log in to access your profile.", "warning")
        return redirect(url_for("login"))

    try:
        # Get available security questions
        questions = db.session.execute(text("SELECT QuestionID, QuestionText FROM SecurityQuestions")).fetchall()
        db.session.commit()

        if request.method == "POST":
            question_id = request.form["questionID"]
            answer = request.form["answer"]

            # Hash the answer before storing
            answer_hash = generate_password_hash(answer)

            db.session.execute(text("""
                CALL SetUserSecurityAnswer(:userID, :questionID, :answerHash)
            """), {
                "userID": session["userID"],
                "questionID": question_id,
                "answerHash": answer_hash
            })
            db.session.commit()

            flash("Security question and answer updated successfully.", "success")
            return redirect(url_for("home"))

        return render_template("edit_profile.html", questions=questions)

    except Exception as e:
        db.session.rollback()
        flash(f"Error loading profile: {str(e)}", "danger")
        return redirect(url_for("home"))

@app.route("/forgot_password", methods=["GET", "POST"])
def forgot_password():
    if request.method == "POST":
        username = request.form["username"]
        question_id = request.form["questionID"]
        answer = request.form["answer"]
        new_password = request.form["new_password"]
        confirm_password = request.form["confirm_password"]

        if new_password != confirm_password:
            flash("Passwords do not match.", "danger")
            return redirect(url_for("forgot_password"))

        try:
            # Step 1: Get user ID
            user = db.session.execute(text("SELECT UserID FROM User WHERE Username = :username"), {"username": username}).fetchone()
            if not user:
                flash("Username not found.", "danger")
                return redirect(url_for("forgot_password"))

            user_id = user.UserID

            # Step 2: Fetch stored answer hash
            stored = db.session.execute(text("""SELECT AnswerHash FROM UserSecurityAnswers WHERE UserID = :userID AND QuestionID = :questionID"""),
                {"userID": user_id, "questionID": question_id}).fetchone()

            if not stored or not check_password_hash(stored.AnswerHash, answer):
                flash("Incorrect answer to the security question.", "danger")
                return redirect(url_for("forgot_password"))

            # Step 3: Hash new password and call stored procedure
            new_hash = generate_password_hash(new_password)
            db.session.execute(text("CALL ChangeUserPassword(:userID, :newHash)"), {"userID": user_id, "newHash": new_hash})
            db.session.commit()

            flash("Password updated successfully. Please log in.", "success")
            return redirect(url_for("login"))

        except Exception as e:
            db.session.rollback()
            flash(f"Error resetting password: {str(e)}", "danger")

    questions = db.session.execute(text("SELECT QuestionID, QuestionText FROM SecurityQuestions")).fetchall()
    return render_template("forgot_password.html", questions=questions)

@app.route('/admin/bed_management', methods=['GET', 'POST'])
def admin_bed_management():
    if "role" not in session or session["role"] != "Admin":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    # Load all beds
    beds = db.session.execute(text("""
        SELECT b.BedID, b.BedType, b.DeptID, d.DeptName, b.PatientID
        FROM Bed b
        LEFT JOIN Department d ON b.DeptID = d.DeptID
    """)).fetchall()

    # Load departments
    departments = db.session.execute(text("SELECT DeptID, DeptName FROM Department")).fetchall()

    if request.method == 'POST':
        action = request.form.get('action')
        bed_id = request.form['bedID']

        try:
            if action == 'create':
                bed_type = request.form['bedType']
                dept_id = request.form['deptID']
                db.session.execute(text("CALL CreateBed(:bedID, :bedType, :deptID)"),
                                   {"bedID": bed_id, "bedType": bed_type, "deptID": dept_id})
                flash(f"Bed {bed_id} created successfully!", "success")

            elif action == 'modify':
                bed_type = request.form['bedType']
                dept_id = request.form['deptID']
                db.session.execute(text("CALL ModifyBed(:bedID, :bedType, :deptID)"),
                                   {"bedID": bed_id, "bedType": bed_type, "deptID": dept_id})
                flash(f"Bed {bed_id} updated successfully!", "success")

            elif action == 'delete':
                db.session.execute(text("CALL DeleteBed(:bedID)"), {"bedID": bed_id})
                flash(f"Bed {bed_id} deleted successfully!", "success")

            db.session.commit()
            return redirect(url_for('admin_bed_management'))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template('admin_bed_management.html', beds=beds, departments=departments)

@app.route('/physician/bed_management', methods=['GET', 'POST'])
def physician_bed_management():
    if 'role' not in session or session['role'] != 'Physician':
        flash("Unauthorized access", "danger")
        return redirect(url_for('login'))

    if request.method == 'POST':
        action = request.form.get('action')
        bed_id = request.form.get('bedID')
        patient_id = request.form.get('patientID')

        try:
            if action == 'assign':
                db.session.execute(text("CALL AssignBedToPatient(:bedID, :patientID)"),
                                   {'bedID': bed_id, 'patientID': patient_id})
                flash("Bed assigned successfully!", "success")
            elif action == 'unassign':
                db.session.execute(text("CALL DischargePatient(:patientID)"),
                                   {'patientID': patient_id})
                flash("Patient discharged from bed.", "info")
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    # Get list of available beds
    available_beds = db.session.execute(text("CALL GetAvailableBeds()")).fetchall()
    patients_without_beds = db.session.execute(text("CALL GetPatientsWithoutBeds()")).fetchall()
    assigned_beds = db.session.execute(text("CALL GetAssignedBeds()")).fetchall()

    

    return render_template('physician_bed_management.html',
                           available_beds=available_beds,
                           patients=patients_without_beds,
                           assigned_beds=assigned_beds)

@app.route("/prescriptions", methods=["GET"])
def view_prescriptions():
    if "userID" not in session or session["role"] != "Patient":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    try:
        patient_id = db.session.execute(text("SELECT PatientID FROM Patient WHERE UserID = :uid"),
                                        {"uid": session["userID"]}).scalar()

        prescriptions = db.session.execute(text("CALL GetPrescriptionsByPatient(:pid)"),
                                           {"pid": patient_id}).fetchall()
        db.session.commit()

        return render_template("prescriptions.html", prescriptions=prescriptions)
    except Exception as e:
        db.session.rollback()
        flash(f"Error fetching prescriptions: {str(e)}", "danger")
        return redirect(url_for("home"))


@app.route("/prescription/update_status", methods=["POST"])
def update_prescription_status():
    if "userID" not in session:
        return jsonify({"error": "Unauthorized"}), 401

    try:
        pres_id = request.form["prescriptionID"]
        new_status = request.form["status"]
        db.session.execute(text("CALL UpdatePrescriptionStatus(:id, :status)"),
                           {"id": pres_id, "status": new_status})
        db.session.commit()
        flash("Prescription status updated!", "success")
    except Exception as e:
        db.session.rollback()
        flash(f"Error updating status: {str(e)}", "danger")

    return redirect(url_for("view_prescriptions"))


@app.route("/notification/add", methods=["POST"])
def add_notification():
    if "userID" not in session:
        return jsonify({"error": "Unauthorized"}), 401

    try:
        msg = request.form["message"]
        status_id = request.form["statusID"]
        priority_id = request.form["priorityID"]

        db.session.execute(text("""CALL AddNotification(:uid, :msg, :sid, :pid)"""),
                           {"uid": session["userID"], "msg": msg, "sid": status_id, "pid": priority_id})
        db.session.commit()
        flash("Notification sent!", "success")
    except Exception as e:
        db.session.rollback()
        flash(f"Error adding notification: {str(e)}", "danger")

    return redirect(url_for("view_notifications"))


@app.route("/notifications", methods=["GET"])
def view_notifications():
    if "userID" not in session:
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    try:
        notifications = db.session.execute(text("CALL GetNotificationsByUser(:uid)"),
                                           {"uid": session["userID"]}).fetchall()
        db.session.commit()
        return render_template("notifications.html", notifications=notifications)
    except Exception as e:
        db.session.rollback()
        flash(f"Error loading notifications: {str(e)}", "danger")
        return redirect(url_for("home"))


@app.route("/lab/results", methods=["GET"])
def view_all_lab_results():
    if "userID" not in session or session["role"] != "Patient":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    try:
        patient_id = db.session.execute(
            text("SELECT PatientID FROM Patient WHERE UserID = :uid"),
            {"uid": session["userID"]}
        ).scalar()

        results = db.session.execute(
            text("CALL GetAllLabResults(:pid)"),
            {"pid": patient_id}
        ).fetchall()

        db.session.commit()
        return render_template("lab_results.html", results=results)

    except Exception as e:
        db.session.rollback()
        flash(f"Error fetching lab results: {str(e)}", "danger")
        return redirect(url_for("home"))


@app.route("/lab/result/<lab_id>", methods=["GET"])
def lab_result_details(lab_id):
    if "userID" not in session:
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    try:
        result = db.session.execute(
            text("CALL GetLabResultDetails(:lab_id)"),
            {"lab_id": lab_id}
        ).fetchone()

        db.session.commit()
        return render_template("lab_result_detail.html", result=result)

    except Exception as e:
        db.session.rollback()
        flash(f"Error fetching lab result details: {str(e)}", "danger")
        return redirect(url_for("view_all_lab_results"))


@app.route("/lab/results/status", methods=["GET"])
def lab_results_by_status():
    if "userID" not in session or session["role"] != "Patient":
        flash("Unauthorized access", "danger")
        return redirect(url_for("login"))

    status = request.args.get("status", "Completed")

    try:
        patient_id = db.session.execute(
            text("SELECT PatientID FROM Patient WHERE UserID = :uid"),
            {"uid": session["userID"]}
        ).scalar()

        results = db.session.execute(
            text("CALL GetLabResultsByStatus(:pid, :status)"),
            {"pid": patient_id, "status": status}
        ).fetchall()

        db.session.commit()
        return render_template("lab_results_filtered.html", results=results, status=status)

    except Exception as e:
        db.session.rollback()
        flash(f"Error filtering lab results: {str(e)}", "danger")
        return redirect(url_for("view_all_lab_results"))



if __name__ == "__main__":
    app.run(debug=True)




























##################JOE'S PYTHON CODE#################################################



@app.route("/soap/subjective/<summary_id>", methods=["GET", "POST"])
def add_subjective_data(summary_id):
    if session.get("role") not in ["Nurse", "Physician"]:
        flash("Unauthorized", "danger")
        return redirect(url_for("home"))

    if request.method == "POST":
        cc = request.form["cc"]
        hpi = request.form["hpi"]
        subjective_id = str(uuid.uuid4())

        try:
            db.session.execute(
                text("CALL AddSubjectiveData(:sid, :sumid, :cc, :hpi)"),
                {"sid": subjective_id, "sumid": summary_id, "cc": cc, "hpi": hpi}
            )
            db.session.commit()
            flash("Subjective data saved.", "success")
            return redirect(url_for("add_objective_data", summary_id=summary_id))
        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("soap/subjective.html", summary_id=summary_id)


from datetime import datetime

@app.route("/soap/objective/<summary_id>", methods=["GET", "POST"])
def add_objective_data(summary_id):
    if session.get("role") not in ["Nurse", "Physician"]:
        flash("Unauthorized", "danger")
        return redirect(url_for("home"))

    if request.method == "POST":
        vitals_id = str(uuid.uuid4())
        objective_id = str(uuid.uuid4())
        bp = request.form["bp"]
        hr = request.form["hr"]
        temp = request.form["temp"]

        try:
            # Add objective record (summary link)
            db.session.execute(text("CALL AddObjectiveData(:summaryID, :objectiveID)"), {
                "summaryID": summary_id,
                "objectiveID": objective_id
            })

            # Add vitals (now linked to ObjectiveDataID, not SummaryID)
            db.session.execute(text("CALL AddVitals(:vitalsID, :objectiveID, :vitalsDate, :bp, :hr, :temp)"), {
                "vitalsID": vitals_id,
                "objectiveID": objective_id,
                "vitalsDate": datetime.now(),
                "bp": bp,
                "hr": hr,
                "temp": temp
            })

            db.session.commit()
            flash("Objective data saved.", "success")
            return redirect(url_for("add_assessment", summary_id=summary_id))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("soap/objective.html", summary_id=summary_id)



@app.route("/soap/assessment/<summary_id>", methods=["GET", "POST"])
def add_assessment(summary_id):
    if session.get("role") != "Physician":
        flash("Only physicians can add assessments.", "danger")
        return redirect(url_for("home"))

    if request.method == "POST":
        assessment_id = str(uuid.uuid4())
        diagnosis = request.form["diagnosis"]
        notes = request.form["notes"]

        try:
            db.session.execute(text("CALL AddAssessment(:assessID, :summaryID, :diagnosis, :notes)"), {
                "assessID": assessment_id,
                "summaryID": summary_id,
                "diagnosis": diagnosis,
                "notes": notes
            })
            db.session.commit()
            flash("Assessment saved.", "success")
            return redirect(url_for("add_plan", summary_id=summary_id))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("soap/assessment.html", summary_id=summary_id)



@app.route("/soap/plan/<summary_id>", methods=["GET", "POST"])
def add_plan(summary_id):
    if session.get("role") != "Physician":
        flash("Only physicians can add plans.", "danger")
        return redirect(url_for("home"))

    if request.method == "POST":
        plan_id = str(uuid.uuid4())
        notes = request.form["notes"]
        followup = request.form.get("followup") == "yes"  # boolean
        status = request.form["status"]

        try:
            db.session.execute(text("""CALL AddPlan(:planID, :summaryID, :createdDate, :followup, :status, :notes)"""), {
                "planID": plan_id,
                "summaryID": summary_id,
                "createdDate": datetime.now(),
                "followup": followup,
                "status": status,
                "notes": notes
            })

            db.session.commit()
            flash("Plan saved. SOAP note completed!", "success")
            return redirect(url_for("physician_dashboard"))

        except Exception as e:
            db.session.rollback()
            flash(f"Error: {str(e)}", "danger")

    return render_template("soap/plan.html", summary_id=summary_id)